from os.path import expanduser, join, isfile, isdir, dirname
from os import makedirs
import json
from string import Template
import requests
from zipfile import ZipFile
from sys import argv


# http://s3.amazonaws.com/Minecraft.Download/versions/1.10.2/1.10.2.jar
# http://s3.amazonaws.com/Minecraft.Download/versions/1.10.2/1.10.2.json
# http://s3.amazonaws.com/Minecraft.Download/versions/1.10.2/minecraft_server.1.10.2.jar


MINECRAFT_DIR = expanduser('~/.minecraft')
VERSIONS_DIR = join(MINECRAFT_DIR, 'versions')
ASSETS_DIR = join(MINECRAFT_DIR, 'assets')
LIBRARIES_DIR = join(MINECRAFT_DIR, 'libraries')
OS = 'linux'
ARCH = 'x86_64'

PARAMETERS = {
    'auth_player_name': 'neumond',
    'auth_uuid': '8e689e3620444061bf12bb6215732cf2',  # http://mcuuid.net/?q=neumond
    'game_directory': MINECRAFT_DIR,
    'assets_root': ASSETS_DIR,
    'auth_access_token': 'LOL',
    'user_type': 'mojang',
    'user_properties': '{}',
}


def assert_keys(dct, *keys):
    assert not (set(dct.keys()) - set(keys)), '{} not in {}'.format(list(dct.keys()), keys)


def download_item(url):
    print('Downloading', url)
    r = requests.get(url)
    assert r.status_code == 200
    c = r.content
    return c


def download_to_file(url, targetpath):
    content = download_item(url)
    makedirs(dirname(targetpath), exist_ok=True)
    with open(targetpath, 'wb') as f:
        f.write(content)


def filter_zip_filenames(zipf, extractcfg):
    assert_keys(extractcfg, 'exclude')
    fnamelist = zipf.namelist()
    for exp in extractcfg.get('exclude', []):
        fnamelist = [p for p in fnamelist if not p.startswith(exp)]
    return fnamelist


def extract_jar(path, targetdir, extractcfg):
    print('Extracting', path)
    with open(path, 'rb') as f:
        with ZipFile(f) as jar:
            makedirs(targetdir, exist_ok=True)
            jar.extractall(path=targetdir, members=filter_zip_filenames(jar, extractcfg))


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
    if act == 'disallow':
        return  # skip this library


class LaunchCommand:
    def __init__(self, ver):
        self.parent = None
        self.jars = []
        self.ver = ver

        VER_DIR = join(VERSIONS_DIR, ver)
        with open(join(VER_DIR, '{}.json'.format(ver))) as f:
            config = json.load(f)
        self.config = config

        if 'inheritsFrom' in config:
            self.parent = LaunchCommand(config['inheritsFrom'])
            self.jars.extend(self.parent.jars)

        jar_version = config.get('jar', ver)
        primary_jar = join(VERSIONS_DIR, jar_version, '{}.jar'.format(jar_version))
        assert isfile(primary_jar)
        self.jars.append(primary_jar)
        self.natives_dir = join(VER_DIR, '{}-natives'.format(jar_version))
        self.main_class = config['mainClass']
        self.argline = Template(config['minecraftArguments']).substitute(
            version_name=ver,
            assets_index_name=config['assets'] if 'assets' in config else self.parent.config['assets'],
            version_type=config['type'],
            **PARAMETERS
        )

        for lib_cfg in config['libraries']:
            for path, url, extract_cfg in self.find_lib(lib_cfg):
                if not isfile(path):
                    download_to_file(url, path)
                if extract_cfg is None:
                    self.jars.append(path)
                else:
                    extract_jar(path, self.natives_dir, extract_cfg)

        if 'assetIndex' in config:
            asset_index_file = join(ASSETS_DIR, 'indexes', '{}.json'.format(config['assetIndex']['id']))
            if not isfile(asset_index_file):
                download_to_file(config['assetIndex']['url'], asset_index_file)
            # with open(asset_index_file, 'rb') as f:
            #     asset_index = json.load(f)
            # self.download_assets(asset_index)

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
                yield jar_path, jar_url, lib_cfg.get('extract')

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
        natives = ':'.join(filter(lambda x: x is not None and isdir(x), [
            self.parent.natives_dir if self.parent is not None else None,
            self.natives_dir,
        ]))
        return 'java -cp "{}" -Djava.library.path="{}" {} {}'.format(
            ':'.join(self.jars),
            natives,
            self.main_class,
            self.argline,
        )

    # def download_assets(self, index):
    #     for folder, items in index.items():
    #         for name, item in items.items():
    #             filename = join(ASSETS_DIR, folder, item['hash'][:2], item['hash'])


def bootstrap_version(ver):
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
    download_to_file('{}/{}.jar'.format(base_url, ver), join(jar_dir, '{}.jar'.format(ver)))
    download_to_file('{}/{}.json'.format(base_url, ver), join(jar_dir, '{}.json'.format(ver)))
    download_to_file(
        '{}/minecraft_server.{}.jar'.format(base_url, ver), join(jar_dir, 'minecraft_server.{}.jar'.format(ver))
    )


if __name__ == '__main__':
    print(LaunchCommand(argv[1]))
    # bootstrap_version(argv[1])
