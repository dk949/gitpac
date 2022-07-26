# gitpac

## Usage

``` sh
gitpac clone URL [-s|--store|DIR] [--no-recurse] [-a|--alias ALIAS]
gitpac fetch ALIAS|DIR
gitpac pull ALIAS|DIR
gitpac switch ALIAS|DIR BRANCH|TAG|HASH|REVISION_ALIAS
gitpac config ALIAS|DIR
gitpac make ALIAS|DIR
gitpac install ALIAS|DIR
```

``` text
$XDG_CONFIG_HOME/gitpac
├── config.yaml
├── recipes
│   ├── pack1.yaml
│   └── pack2.yaml
└── store
    ├── pack1
    │   ├── begin
    │   ├── build.sh
    │   ├── end
    │   ├── .gitignore
    │   ├── middle
    │   └── pack1
    └── pack2
        ├── .gitignore
        ├── Makefile
        └── pack2.c
```

## config.yaml

``` yaml
storeDir: $XDG_BASE_CONFIG/gitpac/store
numRetires: 5;
useSSH: false;
baseUrl:
  - https://github.com/
```

## recipes/pacname.yaml

``` yaml
remote: ""
# or
remote:
  git : ""
  http: ""
  ftp : ""

build  : []
clean  : []
install: []

deps:
  build  : []
  runtime: []

# !!binary
diff: []
```
