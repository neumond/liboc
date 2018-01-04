from os.path import expanduser, join, isfile, isdir, dirname
from os import makedirs
import json
from string import Template
import requests
from zipfile import ZipFile
from collections import OrderedDict
# from sys import argv


MINECRAFT_DIR = expanduser('~/.minecraft_ltest')

VERSIONS_DIR = join(MINECRAFT_DIR, 'versions')
ASSETS_DIR = join(MINECRAFT_DIR, 'assets')
LIBRARIES_DIR = join(MINECRAFT_DIR, 'libraries')
OS = 'linux'
ARCH = 'x86_64'

PARAMETERS = {
    'auth_player_name': 'neumond',
    'auth_uuid': '8e689e36-2044-4061-bf12-bb6215732cf2',  # http://mcuuid.net/?q=neumond
    'game_directory': MINECRAFT_DIR,
    'assets_root': ASSETS_DIR,
    'auth_access_token': '1685aeec-f1f2-4f5f-be41-cc4ec97f55f9',  # random uuid4
    'user_type': 'mojang',
    'user_properties': '{}',
}


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

    def execute_item(self, url, targetpath, force=False):
        if isfile(targetpath) and not force:
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


class LaunchCommand:
    @staticmethod
    def load_config(ver):
        VER_DIR = join(VERSIONS_DIR, ver)
        with open(join(VER_DIR, '{}.json'.format(ver))) as f:
            return json.load(f)

    @property
    def jar_version(self):
        return self.config.get('jar', self.ver)

    @property
    def primary_jar_path(self):
        return join(VERSIONS_DIR, self.jar_version, '{}.jar'.format(self.jar_version))

    @property
    def natives_dir(self):
        return join(VERSIONS_DIR, self.jar_version, '{}-natives'.format(self.jar_version))

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
        return join(ASSETS_DIR, 'indexes', '{}.json'.format(self.config['assetIndex']['id']))

    @property
    def main_class(self):
        return self.config['mainClass']

    @property
    def argline(self):
        return Template(self.config['minecraftArguments']).substitute(
            version_name=self.jar_version,
            assets_index_name=self.config['assets'] if 'assets' in self.config else self.parent.config['assets'],
            version_type=self.config['type'],
            **PARAMETERS
        )

    def __init__(self, ver):
        self.ver = ver
        self.parent = None
        self.config = self.load_config(ver)
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
            for path, url, extract_cfg in self.find_lib(lib_cfg):
                if not isfile(path):
                    self.download_queue.add(url, path)
                if extract_cfg is None:
                    self.jars.append(path)
                else:
                    self.extract_queue.add(path, extract_cfg)

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
                jar_path = join(LIBRARIES_DIR, lib_cfg['downloads']['artifact']['path'])
                jar_url = lib_cfg['downloads']['artifact']['url']
                yield jar_path, jar_url, None

            if 'natives' in lib_cfg:
                nat = lib_cfg['downloads']['classifiers'][lib_cfg['natives'][OS]]
                native_jar_path = join(LIBRARIES_DIR, nat['path'])
                native_jar_url = nat['url']
                yield native_jar_path, native_jar_url, lib_cfg.get('extract')
        else:
            # old style for forge
            if not lib_cfg.get('clientreq', True):
                return
            lns, lname, lver = lib_cfg['name'].split(':')
            jar_path = join(LIBRARIES_DIR, *lns.split('.'), lname, lver, '{}-{}.jar'.format(lname, lver))

            default_maven = 'http://repo1.maven.org/maven2/'
            if lns.startswith('net.minecraft'):
                default_maven = 'https://libraries.minecraft.net/'
            elif lns == 'lzma':
                default_maven = 'https://repo.spongepowered.org/maven/'
            maven_url = lib_cfg.get('url', default_maven).rstrip('/') + '/'
            jar_url = maven_url + '/'.join([*lns.split('.'), lname, lver, '{}-{}.jar'.format(lname, lver)])

            yield jar_path, jar_url, lib_cfg.get('extract')

        return

    def __str__(self):
        return 'java -cp "{}" -Djava.library.path="{}" {} {}'.format(
            ':'.join(self.jars),
            self.natives_line,
            self.main_class,
            self.argline,
        )

    def download_libraries(self, **kw):
        makedirs(LIBRARIES_DIR, exist_ok=True)
        self.download_queue.execute(**kw)

    def extract_natives(self, **kw):
        self.extract_queue.execute(**kw)

    def download_assets(self, **kw):
        assert(isfile(self.asset_index_file))
        with open(self.asset_index_file, 'r') as f:
            index = json.load(f)
        makedirs(ASSETS_DIR, exist_ok=True)
        dq = DownloadQueue()
        for folder, items in index.items():
            for name, item in items.items():
                h2 = item['hash'][:2]
                hf = item['hash']
                dq.add(
                    'http://resources.download.minecraft.net/{}/{}'.format(h2, hf),
                    join(ASSETS_DIR, folder, h2, hf)
                )
        dq.execute(**kw)


def bootstrap_version(ver, **kw):
    # keyword parameters
    # force: bool  -- redownload everything

    dq = DownloadQueue()
    jar_dir = join(VERSIONS_DIR, ver)
    makedirs(jar_dir, exist_ok=True)
    for k in ('saves', 'logs', 'resourcepacks'):
        makedirs(join(MINECRAFT_DIR, k), exist_ok=True)

    with open(join(MINECRAFT_DIR, 'launcher_profiles.json'), 'w') as f:
        json.dump({
            'profiles': {
                ver: {
                    'name': ver,
                    'lastVersionId': ver,
                }
            },
            'selectedProfile': ver,
        }, f)

    base_url = 'http://s3.amazonaws.com/Minecraft.Download/versions/{}'.format(ver)
    dq.add('{}/{}.jar'.format(base_url, ver), join(jar_dir, '{}.jar'.format(ver)))
    dq.add('{}/{}.json'.format(base_url, ver), join(jar_dir, '{}.json'.format(ver)))
    dq.add(
        '{}/minecraft_server.{}.jar'.format(base_url, ver), join(jar_dir, 'minecraft_server.{}.jar'.format(ver))
    )
    dq.execute(**kw)

    lc = LaunchCommand(ver)
    lc.download_libraries(**kw)
    lc.extract_natives(**kw)
    lc.download_assets(**kw)
    return str(lc)


if __name__ == '__main__':
    print(bootstrap_version('1.12.2'))
