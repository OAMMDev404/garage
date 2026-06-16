# Taller App — Inventario y Finanzas

Aplicación Flutter para gestionar inventario, ventas, gastos, pedidos por
encargo e informes financieros de un taller mecánico. Funciona en **Android
(APK)** y **Windows (ejecutable .exe)** usando una base de datos local
**SQLite** — no requiere internet ni Play Store.

---

## 1. Requisitos previos

1. Instalar **Flutter SDK**: https://docs.flutter.dev/get-started/install
2. Verificar la instalación:
   ```bash
   flutter doctor
   ```
   Asegúrate de que estén en verde:
   - Flutter
   - Android toolchain (para generar el APK)
   - Visual Studio (para generar el .exe en Windows)

---

## 2. Instalar dependencias del proyecto

Desde la carpeta raíz del proyecto (`taller_app/`):

```bash
flutter pub get
```

---

## 3. Ejecutar en modo desarrollo (para probar)

```bash
# En un emulador/celular Android conectado
flutter run

# En Windows (desktop)
flutter config --enable-windows-desktop
flutter run -d windows
```

---

## 4. Generar el APK (Android)

```bash
flutter build apk --release
```

El archivo quedará en:
```
build/app/outputs/flutter-apk/app-release.apk
```

Copia ese archivo al celular (por USB, WhatsApp, etc.) y ábrelo para
instalarlo. Es posible que Android pida activar "Instalar apps de orígenes
desconocidos" — eso es normal porque no viene de Play Store.

> Si quieres un APK más pequeño separado por arquitectura:
> ```bash
> flutter build apk --release --split-per-abi
> ```

---

## 5. Generar el ejecutable para PC (Windows)

```bash
flutter config --enable-windows-desktop
flutter build windows --release
```

El ejecutable y todos sus archivos necesarios quedarán en:
```
build/windows/x64/runner/Release/
```

Para distribuirlo, copia **toda la carpeta `Release`** (no solo el .exe) a la
PC donde se va a usar — contiene las DLLs necesarias para que funcione.

---

## 6. Estructura del proyecto

```
lib/
├── main.dart                  # Punto de entrada
├── theme.dart                 # Colores y tema (amarillo / azul / negro)
├── db/
│   └── database_helper.dart   # Toda la lógica de SQLite (CRUD, reportes)
├── models/                     # Clases del diagrama de clases (Producto, Venta, etc.)
└── screens/
    ├── dashboard_screen.dart   # Pantalla principal
    ├── inventario_screen.dart  # Listado, búsqueda y filtros de productos
    ├── producto_form_screen.dart # Crear / editar / eliminar producto
    ├── venta_screen.dart       # Registrar ventas (carrito)
    ├── encargos_screen.dart    # Pedidos por encargo
    └── reportes_screen.dart    # Informes financieros + exportar PDF
```

---

## 7. Datos iniciales

Al primer arranque, la app crea automáticamente la base de datos
`taller_app.db` con categorías base: Repuestos, Lubricantes, Herramientas,
Eléctrico, Llantas y Otros.

---

## 8. Pendientes / mejoras sugeridas

- [ ] Pantalla de **login** usando `DatabaseHelper.login()` (ya implementado
  en la base de datos, falta conectar la UI)
- [ ] Pantalla de **gastos** (registrar gasto — el modelo y la base de datos
  ya están listos en `Gasto` y `crearGasto()`)
- [ ] Tabla de **auditoría/log** (REQ-15) para registrar quién hizo qué
- [ ] Filtro de reportes por **rango de fechas personalizado** (REQ-11)
