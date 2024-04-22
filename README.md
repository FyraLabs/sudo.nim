# sudo.nim

Detect if you are running as root, restart self with sudo if needed or setup uid zero when running with the SUID flag set.

- GitHub: https://github.com/FyraLabs/sudo.nim
- Nimble: https://nimble.directory/pkg/sudo

## Installation

In your `<pkgname>.nimble` file:
```nim
requires "sudo >= 0.1.0"
```

Then run `nimble install --depsOnly`.

## Example

```nim
import sudo

discard sudo()

# or…
discard sudo(["QT_"])  # this exports environment variables that start with QT_
```
