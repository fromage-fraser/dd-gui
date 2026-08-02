# Build deployment

Whenever Codex produces a new DD_GUI package build, run `./scripts/build-and-upload.ps1` instead of invoking `muddle` directly. The helper rebuilds the package and uploads `build/DD_GUI.mpackage` and `build/DD_GUI.xml` to the production GUI directory.

The FTP credential is stored only in the ignored `.dd-gui-ftp.netrc` file. Never commit, print, or otherwise expose that file or its contents.
