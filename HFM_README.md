# TUM-HFM SWAT+ Group Repository

This is the TUM Hydrology and River Basin Management (HFM) fork of the official [SWAT+ model](https://github.com/swat-model/swatplus), maintained for internal group use and collaborative development.

For the official SWAT+ documentation, see [swatplus.gitbook.io/io-docs](https://swatplus.gitbook.io/io-docs).

---

## Download Executables

Pre-compiled executables for all platforms are available on the [Releases page](https://github.com/TUM-HFM/swatplus/releases).

| File contains | Platform | Notes |
|---|---|---|
| `gnu-win` | Windows | ✅ No installation needed |
| `ifx-win` | Windows | ⚠️ Requires [Intel Redistributable DLLs](https://www.intel.com/content/www/us/en/developer/articles/tool/compilers-redistributable-libraries-by-version.html) |
| `gnu-lin` | Linux | ✅ No installation needed |
| `ifx-lin` | Linux | ✅ No installation needed |
| `gnu-mac` | macOS | ✅ No installation needed |

---

## Branch Structure

| Branch | Purpose |
|---|---|
| `main` | Mirrors the official SWAT+ main branch |
| `HFM/61.0.2` | Group's stable working branch based on SWAT+ 61.0.2 |

#### New official swat+ releases will be added as branch from time to time
---

## Contributing

### Working on group features (HFM/61.0.2)

1. Create a branch from `HFM/61.0.2`:
```bash
git switch HFM/61.0.2
git pull
git switch -c yourname/feature-description
```
2. Make your changes and commit:
```bash
git add src/modified_file.f90
git commit -m "Short description of what changed and why"
git push origin yourname/feature-description
```
3. Open a Pull Request on GitHub — **make sure to set the base branch to `HFM/61.0.2`**, not `main`
4. Wait for review and approval

### Contributing to official SWAT+ (main)

1. Create a branch from `main`:
```bash
git switch main
git pull
git switch -c yourname/contribution-description
```
2. Make your changes, commit and push
3. Open a Pull Request — base branch should be `main`
4. Once merged internally, a separate PR can be opened to the [official SWAT+ repo](https://github.com/swat-model/swatplus)

---

## Contact

For questions about this repository, contact the group repository maintainer (moritz.wirthensohn@tum.de).
