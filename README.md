# RubikLog

Proyecto de Cubo de Rubik 3x3x3 en SWI-Prolog con una interfaz web ligera.

## Estructura

- `prolog/`: módulos del cubo y del servidor
- `tests/`: pruebas
- `web/`: interfaz web
- `docs/`: documentación

## Comandos

```sh
swipl -s prolog/server.pl
swipl -g run_tests -t halt tests/test_cube.pl
```
