# Build deployment

After making project changes, commit them, push them to the upstream repository, open a pull request, merge it to the upstream default branch, and update the local checkout to the merged upstream state.

Whenever Codex produces a new DD_GUI package build, run `./scripts/build-and-upload.ps1` instead of invoking `muddle` directly. The helper rebuilds the package and uploads `build/DD_GUI.mpackage` and `build/DD_GUI.xml` to the production GUI directory.

After making GUI/package source changes, always produce and upload a new DD_GUI package build with `./scripts/build-and-upload.ps1`.

The FTP credential is stored only in the ignored `.dd-gui-ftp.netrc` file. Never commit, print, or otherwise expose that file or its contents.
