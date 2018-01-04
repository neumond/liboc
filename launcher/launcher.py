from os.path import expanduser, join, isfile, isdir, dirname
from os import makedirs
import json
from string import Template
import requests
from zipfile import ZipFile
# from sys import argv


# http://s3.amazonaws.com/Minecraft.Download/versions/1.10.2/1.10.2.jar
# http://s3.amazonaws.com/Minecraft.Download/versions/1.10.2/1.10.2.json
# http://s3.amazonaws.com/Minecraft.Download/versions/1.10.2/minecraft_server.1.10.2.jar


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

    def add(self, *a):
        self.q.append(a)

    def extend_from(self, ext_q):
        self.q.extend(ext_q)

    def execute(self):
        for item in self.q:
            self.execute_item(*item)
        self.q.clear()

    def dump(self):
        for item in self.q:
            self.dump_item(*item)


class DownloadQueue(BaseQueue):
    @staticmethod
    def download_item(url):
        print('Downloading', url)
        r = requests.get(url)
        assert r.status_code == 200
        c = r.content
        return c

    @classmethod
    def download_to_file(cls, url, targetpath, force=False):
        if isfile(targetpath) and not force:
            return
        content = cls.download_item(url)
        makedirs(dirname(targetpath), exist_ok=True)
        with open(targetpath, 'wb') as f:
            f.write(content)

    def execute_item(self, url, targetpath):
        self.download_to_file(url, targetpath)

    def dump_item(self, url, targetpath):
        print('{} → {}'.format(url, targetpath))


class ExtractQueue(BaseQueue):
    @staticmethod
    def filter_zip_filenames(zipf, extractcfg):
        assert_keys(extractcfg, 'exclude')
        fnamelist = zipf.namelist()
        for exp in extractcfg.get('exclude', []):
            fnamelist = [p for p in fnamelist if not p.startswith(exp)]
        return fnamelist

    @classmethod
    def extract_jar(cls, path, targetdir, extractcfg):
        print('Extracting', path)
        with open(path, 'rb') as f:
            with ZipFile(f) as jar:
                makedirs(targetdir, exist_ok=True)
                jar.extractall(path=targetdir, members=cls.filter_zip_filenames(jar, extractcfg))

    def __init__(self, natives_dir):
        super().__init__()
        self.natives_dir = natives_dir

    def execute_item(self, path, extract_cfg):
        self.extract_jar(path, self.natives_dir, extract_cfg)

    def dump_item(self, path, extract_cfg):
        print('{} {}'.format(path, extract_cfg))


def execute_rules(rule_cfg):
    act = 'disallow'
    for rule in rule_cfg:
        assert_keys(rule, 'action', 'os')
        if 'os' in rule and rule['os']['name'] != OS:
            # print('skip rule', rule)
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

        u, r2 = set(), []
        for item in r:
            if item in u:
                continue
            u.add(item)
            r2.append(item)

        return ':'.join(r2)

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

    def download_libraries(self):
        self.download_queue.execute()

    def extract_natives(self):
        self.extract_queue.execute()

    def download_assets(self, index):
        with open(self.asset_index_file, 'rb') as f:
            index = json.load(f)
        for folder, items in index.items():
            for name, item in items.items():
                filename = join(ASSETS_DIR, folder, item['hash'][:2], item['hash'])
                print(filename)
                # TODO:


def bootstrap_version(ver):
    dq = DownloadQueue()
    jar_dir = join(VERSIONS_DIR, ver)
    makedirs(jar_dir, exist_ok=True)
    makedirs(ASSETS_DIR, exist_ok=True)
    makedirs(LIBRARIES_DIR, exist_ok=True)

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
    dq.execute()


if __name__ == '__main__':
    bootstrap_version('1.12.2')
    lc = LaunchCommand('1.12.2')
    lc.download_libraries()
    lc.extract_natives()
    # lc.download_queue.dump()
    # print()
    # lc.extract_queue.dump()
    # print()
    # print(lc)
