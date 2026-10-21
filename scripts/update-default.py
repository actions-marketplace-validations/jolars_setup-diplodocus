import os
import re
from pathlib import Path

release = os.environ["DIPLODOCUS_RELEASE"]
if not re.fullmatch(r"v[0-9]+\.[0-9]+\.[0-9]+", release):
    raise SystemExit(f"Expected a stable release, got {release}")
version = release[1:]
action = Path("action.yml")
source = action.read_text()
current = re.search(r'    default: "([0-9]+\.[0-9]+\.[0-9]+)"', source)
if current is None:
    raise SystemExit("Cannot find the pinned default CLI version")
if tuple(map(int, version.split("."))) <= tuple(map(int, current[1].split("."))):
    raise SystemExit(0)
action.write_text(source.replace(current[0], f'    default: "{version}"', 1))
readme = Path("README.md")
readme.write_text(readme.read_text().replace(f"`{current[1]}`", f"`{version}`"))
