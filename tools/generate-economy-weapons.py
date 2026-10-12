import argparse
from pathlib import Path
import zipfile

GUNS = ('m4', 'ak47', 'mp5', 'ak74u')
SIGHT_FIELDS = {'clipName', 'adsFireAnim', 'adsLastShotAnim', 'adsUpAnim', 'adsDownAnim', 'hideTags'}


def parts(data):
    values = data.decode('latin1').split('\\')
    if values[0] != 'WEAPONFILE' or len(values) % 2 != 1:
        raise ValueError('Invalid weapon definition.')
    return values


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--game', type=Path, default=Path('C:/Program Files (x86)/Steam/steamapps/common/Call of Duty 4'))
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    repo = Path(__file__).resolve().parent.parent
    with zipfile.ZipFile(args.game / 'main/iw_11.iwd') as archive:
        for gun in GUNS:
            base = parts((repo / ('weapons/mp/' + gun + '_mp')).read_bytes())
            stock = parts(archive.read('weapons/mp/' + gun + '_reflex_mp'))
            sight = dict(zip(stock[1::2], stock[2::2]))
            for index in range(1, len(base), 2):
                if base[index] in SIGHT_FIELDS:
                    base[index + 1] = sight[base[index]]
            expected = '\\'.join(base).encode('latin1')
            target = repo / ('weapons/mp/' + gun + '_reflex_mp')
            if args.check:
                if target.read_bytes() != expected:
                    raise ValueError('Outdated or changed weapon definition: ' + str(target))
            else:
                target.write_bytes(expected)
    print('Verified Promod red-dot definitions.' if args.check else 'Generated Promod red-dot definitions.')


if __name__ == '__main__':
    main()
