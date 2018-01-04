from os.path import expanduser, join, isfile, isdir, dirname, getsize
from os import makedirs
import json
from string import Template
import requests
from zipfile import ZipFile
from collections import OrderedDict
from copy import deepcopy
from uuid import uuid4
from hashlib import sha1 as sha1_hash
# from sys import argv


OS = 'linux'
ARCH = 'x86_64'


def assert_keys(dct, *keys):
    assert not (set(dct.keys()) - set(keys)), '{} not in {}'.format(list(dct.keys()), keys)


class BaseQueue:
    def __init__(self):
        self.q = []

    def add(self, *a, **kw):
        self.q.append((a, kw))

    def extend_from(self, ext_q):
        self.q.extend(ext_q)

    def execute(self, **okw):
        for a, kw in self.q:
            self.execute_item(*a, **kw, **okw)
        self.q.clear()

    def dump(self):
        for a, kw in self.q:
            print('{} {}'.format(a, kw))


class DownloadQueue(BaseQueue):
    @staticmethod
    def download_item(url):
        print('Downloading', url)
        r = requests.get(url)
        assert r.status_code == 200
        c = r.content
        return c

    def execute_item(self, url, targetpath, force=False, size=None, sha1=None):
        if isfile(targetpath):
            if size is not None:
                assert size == getsize(targetpath)
            if sha1 is not None:
                with open(targetpath, 'rb') as f:
                    assert sha1_hash(f.read()).hexdigest() == sha1
            if not force:
                return
        content = self.download_item(url)
        makedirs(dirname(targetpath), exist_ok=True)
        with open(targetpath, 'wb') as f:
            f.write(content)


class ExtractQueue(BaseQueue):
    @staticmethod
    def filter_zip_filenames(zipf, extractcfg):
        assert_keys(extractcfg, 'exclude')
        fnamelist = zipf.namelist()
        for exp in extractcfg.get('exclude', []):
            fnamelist = [p for p in fnamelist if not p.startswith(exp)]
        return fnamelist

    def __init__(self, natives_dir):
        super().__init__()
        self.natives_dir = natives_dir

    def execute_item(self, path, extractcfg, force=False):
        with open(path, 'rb') as f:
            with ZipFile(f) as jar:
                fnamelist = self.filter_zip_filenames(jar, extractcfg)

                extract = True
                if not force:
                    # check all files exist
                    for fname in fnamelist:
                        if not isfile(join(self.natives_dir, fname)):
                            break
                    else:
                        extract = False

                if extract:
                    print('Extracting', path)
                    makedirs(self.natives_dir, exist_ok=True)
                    jar.extractall(path=self.natives_dir, members=fnamelist)


def execute_rules(rule_cfg):
    act = 'disallow'
    for rule in rule_cfg:
        assert_keys(rule, 'action', 'os')
        if 'os' in rule and rule['os']['name'] != OS:
            continue  # skip this rule
        act = rule['action']
    assert act in ('allow', 'disallow')
    return act


class PathManager:
    def __init__(self, base_dir):
        self.base_dir = base_dir

    @property
    def versions_dir(self):
        return join(self.base_dir, 'versions')

    @property
    def assets_dir(self):
        return join(self.base_dir, 'assets')

    @property
    def libraries_dir(self):
        return join(self.base_dir, 'libraries')


class Bootstrapper:
    def __init__(self, path_manager, ver):
        self.path_manager = path_manager
        self.ver = ver

    @property
    def jar_dir(self):
        return join(self.path_manager.versions_dir, self.ver)

    def download(self, **kw):
        dq = DownloadQueue()
        makedirs(self.jar_dir, exist_ok=True)

        base_url = 'http://s3.amazonaws.com/Minecraft.Download/versions/{}'.format(self.ver)
        dq.add(
            '{}/{}.jar'.format(base_url, self.ver),
            join(self.jar_dir, '{}.jar'.format(self.ver))
        )
        dq.add(
            '{}/{}.json'.format(base_url, self.ver),
            join(self.jar_dir, '{}.json'.format(self.ver))
        )
        dq.add(
            '{}/minecraft_server.{}.jar'.format(base_url, self.ver),
            join(self.jar_dir, 'minecraft_server.{}.jar'.format(self.ver))
        )
        dq.execute(**kw)

    def precreate_dirs(self):
        for k in ('saves', 'logs', 'resourcepacks'):
            makedirs(join(self.path_manager.base_dir, k), exist_ok=True)


class LaunchCommand:
    def load_config(self):
        with open(join(
            self.path_manager.versions_dir,
            self.ver,
            '{}.json'.format(self.ver)
        )) as f:
            return json.load(f)

    @property
    def jar_version(self):
        return self.config.get('jar', self.ver)

    @property
    def primary_jar_dir(self):
        return join(self.path_manager.versions_dir, self.jar_version)

    @property
    def primary_jar_path(self):
        return join(self.primary_jar_dir, '{}.jar'.format(self.jar_version))

    @property
    def natives_dir(self):
        return join(self.primary_jar_dir, '{}-natives'.format(self.jar_version))

    @property
    def natives_dirs(self):
        r = []
        if self.parent is not None:
            r.extend(self.parent.natives_dirs)
        if isdir(self.natives_dir):
            r.append(self.natives_dir)

        r2 = OrderedDict()
        for item in r:
            r2[item] = True

        return [k for k in r2.keys()]

    @property
    def natives_line(self):
        return ':'.join(self.natives_dirs)

    @property
    def asset_index_file(self):
        return join(
            self.path_manager.assets_dir,
            'indexes',
            '{}.json'.format(self.config['assetIndex']['id'])
        )

    @property
    def main_class(self):
        return self.config['mainClass']

    @property
    def argline(self):
        return Template(self.config['minecraftArguments']).substitute(
            version_name=self.jar_version,
            assets_index_name=self.config['assets'] if 'assets' in self.config else self.parent.config['assets'],
            version_type=self.config['type'],
            game_directory=self.path_manager.base_dir,
            assets_root=self.path_manager.assets_dir,
            **self.aparams
        )

    def __init__(self, path_manager, ver, nickname, auth_uuid):
        self.path_manager = path_manager
        self.ver = ver
        self.aparams = {
            'auth_player_name': nickname,
            'auth_uuid': auth_uuid,
            'auth_access_token': str(uuid4()),
            'user_type': 'mojang',
            'user_properties': '{}'
        }

        self.parent = None
        self.config = self.load_config()
        assert isfile(self.primary_jar_path)
        self.jars = [self.primary_jar_path]

        self.download_queue = DownloadQueue()
        self.extract_queue = ExtractQueue(self.natives_dir)

        if 'inheritsFrom' in self.config:
            self.parent = LaunchCommand(self.config['inheritsFrom'])
            self.jars.extend(self.parent.jars)
            self.download_queue.extend_from(self.parent.download_queue)
            self.extract_queue.extend_from(self.parent.extract_queue)

        for lib_cfg in self.config['libraries']:
            for item in self.find_lib(lib_cfg):
                path = join(self.path_manager.libraries_dir, item['path'])
                self.download_queue.add(item['url'], path, sha1=item['sha1'], size=item['size'])
                if item['extract'] is None:
                    self.jars.append(path)
                else:
                    self.extract_queue.add(path, item['extract'])

        if 'assetIndex' in self.config:
            self.download_queue.add(self.config['assetIndex']['url'], self.asset_index_file)

    def find_lib(self, lib_cfg):
        assert_keys(
            lib_cfg,
            'name', 'downloads', 'rules', 'natives', 'extract',  # new style configs
            'url', 'serverreq', 'clientreq', 'checksums', 'comment',  # old style (forge)
        )

        if 'rules' in lib_cfg:
            if execute_rules(lib_cfg['rules']) == 'disallow':
                return  # skip this library

        if 'downloads' in lib_cfg:
            if 'artifact' in lib_cfg['downloads']:
                jar = lib_cfg['downloads']['artifact']
                yield {
                    'extract': None,
                    **{k: jar.get(k) for k in ('path', 'url', 'sha1', 'size')}
                }

            if 'natives' in lib_cfg:
                nat = lib_cfg['downloads']['classifiers'][lib_cfg['natives'][OS]]
                assert lib_cfg.get('extract') is not None
                yield {
                    'extract': lib_cfg['extract'],
                    **{k: nat.get(k) for k in ('path', 'url', 'sha1', 'size')}
                }
        else:
            # old style for forge
            # TODO
            if not lib_cfg.get('clientreq', True):
                return
            lns, lname, lver = lib_cfg['name'].split(':')
            parts = [*lns.split('.'), lname, lver, '{}-{}.jar'.format(lname, lver)]

            default_maven = 'http://repo1.maven.org/maven2/'
            if lns.startswith('net.minecraft'):
                default_maven = 'https://libraries.minecraft.net/'
            elif lns == 'lzma':
                default_maven = 'https://repo.spongepowered.org/maven/'
            maven_url = lib_cfg.get('url', default_maven).rstrip('/') + '/'

            assert lib_cfg.get('extract') is None
            yield {
                'extract': None,
                'path': join(*parts),
                'url': maven_url + '/'.join(parts),
                'sha1': None,
                'size': None
            }

    def __str__(self):
        return 'java -cp "{}" -Djava.library.path="{}" {} {}'.format(
            ':'.join(self.jars),
            self.natives_line,
            self.main_class,
            self.argline,
        )

    def download_libraries(self, **kw):
        makedirs(self.path_manager.libraries_dir, exist_ok=True)
        self.download_queue.execute(**kw)

    def extract_natives(self, **kw):
        self.extract_queue.execute(**kw)

    def download_assets(self, **kw):
        assert(isfile(self.asset_index_file))
        with open(self.asset_index_file, 'r') as f:
            index = json.load(f)
        makedirs(self.path_manager.assets_dir, exist_ok=True)
        dq = DownloadQueue()
        for folder, items in index.items():
            for name, item in items.items():
                # print(item)
                h2 = item['hash'][:2]
                hf = item['hash']
                dq.add(
                    'http://resources.download.minecraft.net/{}/{}'.format(h2, hf),
                    join(self.path_manager.assets_dir, folder, h2, hf),
                    size=item['size'],
                    sha1=item['hash']
                )
        dq.execute(**kw)


class LauncherProfiles:
    @property
    def pfile(self):
        return join(self.path_manager.base_dir, 'launcher_profiles.json')

    def __init__(self, path_manager):
        self.path_manager = path_manager
        self.prev_data = None
        if isfile(self.pfile):
            with open(self.pfile, 'r') as f:
                self.data = json.load(f)
                self.prev_data = deepcopy(self.data)
        else:
            self.data = {
                'profiles': {},
                'selectedProfile': None
            }

    def add_profile(self, ver):
        self.data['profiles'][ver] = {
            'name': ver,
            'lastVersionId': ver
        }

    def select_profile(self, ver):
        assert(ver in self.data['profiles'])
        self.data['selectedProfile'] = ver

    def flush(self):
        if self.data == self.prev_data:
            return
        with open(self.pfile, 'w') as f:
            json.dump(self.data, f)
        self.prev_data = deepcopy(self.data)


def bootstrap_version(base_dir, ver, nickname, auth_uuid, **kw):
    # keyword parameters
    # force: bool  -- redownload everything
    pm = PathManager(base_dir)

    b = Bootstrapper(pm, ver)
    b.precreate_dirs()
    b.download(**kw)

    pf = LauncherProfiles(pm)
    pf.add_profile(ver)
    pf.select_profile(ver)
    pf.flush()

    lc = LaunchCommand(pm, ver, nickname, auth_uuid)
    lc.download_libraries(**kw)
    lc.extract_natives(**kw)
    lc.download_assets(**kw)
    return str(lc)


if __name__ == '__main__':
    print(bootstrap_version(
        expanduser('~/.minecraft_ltest'),
        '1.12.2',
        'neumond',
        '8e689e36-2044-4061-bf12-bb6215732cf2'  # http://mcuuid.net/?q=neumond'
    ))
