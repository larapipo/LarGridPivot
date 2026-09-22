# LarGridPivot

Pivot Grid VCL reutilizable para Delphi.

## Componente

El componente visual es:

```delphi
TLarGridPivot
```

Se registra en la paleta:

```text
LarSoft
```

La aplicación sólo necesita asignar un `TDataSource` y configurar los campos del pivot. El componente no depende de FireDAC ni de Firebird; trabaja contra `TDataSet/TDataSource`.

## Paquetes

La instalación está separada en dos paquetes:

- `Packages\LarGridPivotRuntime.dpk`: código de ejecución.
- `Packages\LarGridPivotDesign.dpk`: registro del componente en el IDE.

Esta separación permite que las futuras modificaciones se hagan sobre el componente y sus unidades sin mezclar el código del Demo con la instalación del IDE.

## Instalación en Delphi

1. Agregar la carpeta `Source` al **Library Path** de Delphi o al Search Path del proyecto.
2. Abrir `Packages\LarGridPivotRuntime.dpk`.
3. Ejecutar **Build**.
4. Abrir `Packages\LarGridPivotDesign.dpk`.
5. Ejecutar **Build** y luego **Install**.
6. Verificar que aparezca `TLarGridPivot` en la paleta **LarSoft**.

Si había una versión anterior instalada, quitar primero `LarGridPivotDesign` desde **Component > Install Packages** y volver a instalar el paquete actualizado.

## Uso básico

```delphi
LarGridPivot1.DataSource := DataSource1;
LarGridPivot1.Rebuild;
```

Los campos pueden configurarse desde código:

```delphi
with LarGridPivot1.FieldByName('RUBRO') do
begin
  Caption := 'Rubro';
  Area := paRow;
  AreaIndex := 0;
end;

with LarGridPivot1.FieldByName('MES') do
begin
  Caption := 'Mes';
  Area := paColumn;
  AreaIndex := 0;
end;

with LarGridPivot1.FieldByName('TOTAL') do
begin
  Caption := 'Venta';
  Area := paData;
  AreaIndex := 0;
  SummaryType := psSum;
  DisplayFormat := '#,##0.00';
end;

LarGridPivot1.Rebuild;
```

## Funcionalidad actual

Incluye agrupación jerárquica, filas y columnas dinámicas, múltiples campos de datos, filtros, orden, subtotales y total general, selección y copia al portapapeles, vistas guardadas, exportación CSV/XLSX, impresión, vista previa, configuración de impresión y soporte para VCL Styles.

El proyecto `Demo` queda únicamente como aplicación de prueba y ejemplo de uso.
