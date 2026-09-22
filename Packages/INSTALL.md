# Instalación de LarGridPivot en Delphi

## 1. Ruta de unidades

Agregar la carpeta:

```text
<ruta del repositorio>\Source
```

a:

```text
Tools > Options > Language > Delphi > Library > Library path
```

para la plataforma que se utilice, por ejemplo Win32.

## 2. Compilar runtime

Abrir:

```text
Packages\LarGridPivotRuntime.dpk
```

y elegir **Build**.

No se instala este paquete desde la paleta; contiene las unidades que usa el componente en ejecución.

## 3. Instalar design-time

Abrir:

```text
Packages\LarGridPivotDesign.dpk
```

Elegir **Build** y después **Install**.

Delphi debe informar que se registró:

```text
TLarGridPivot
```

El componente aparecerá en la categoría:

```text
LarSoft
```

## 4. Actualizaciones futuras

Después de hacer `git pull`:

1. cerrar los proyectos que estén usando LarGridPivot;
2. hacer Build de `LarGridPivotRuntime.dpk`;
3. hacer Build de `LarGridPivotDesign.dpk`;
4. si Delphi no refresca el componente, desinstalar e instalar nuevamente `LarGridPivotDesign`.

El Demo no forma parte del paquete instalado.
