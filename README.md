# B737 Tools

**Aplicación de referencia para Técnicos de Mantenimiento de Aeronaves (TMAs) — Boeing 737**

---

## Descripción

B737 Tools es una aplicación móvil Flutter para iOS y Android diseñada para uso sin conexión. Proporciona acceso rápido a información técnica de referencia del Boeing 737: interruptores de circuito (CB), manual de aislamiento de fallos (FIM), números de parte comunes (PN), checklists de revisión y un sistema de favoritos.

> **Aviso de seguridad:** Esta aplicación es únicamente una herramienta de referencia. No sustituye en ningún caso la documentación oficial aprobada ni los procedimientos reglamentarios. Consulte siempre la documentación técnica oficial aprobada antes de realizar cualquier acción de mantenimiento.

---

## Módulos

| Tab | Módulo | Descripción |
|-----|--------|-------------|
| 1 | **Breakers (CB)** | Lista de interruptores de circuito B737 con referencia de panel, grid y AMM |
| 2 | **FIM / Fallos** | Consulta rápida del Fault Isolation Manual |
| 3 | **Common PN** | Referencia de números de parte; permite añadir PNs personalizados |
| 4 | **Revisiones** | Checklists de Transit Check y Daily Check con undo por deslizamiento |
| 5 | **Favoritos** | Acceso rápido a los items marcados como favoritos de todos los módulos |
| 6 | **Esquemas** | Visor de esquemas PDF organizados por ATA con herramienta de anotación persistente |

---

## Tecnología

- **Framework:** Flutter (iOS + Android)
- **SDK mínimo:** Flutter ≥ 3.0.0 / Dart ≥ 3.0.0
- **Estado:** `StatefulWidget` + `SharedPreferences`
- **Persistencia:** Local únicamente (`shared_preferences`) — sin conexión de red
- **Red:** Cero peticiones de red — funciona 100% offline

### Dependencias principales

```yaml
shared_preferences: ^2.2.2   # almacenamiento local clave-valor
image_picker: ^1.1.2          # adjuntar fotos en reportes
share_plus: ^7.2.2            # exportar CSV via hoja de compartir del SO
path_provider: ^2.1.2         # directorio temporal para exportación CSV
```

---

## Versión

**Beta 0.3** — Marzo 2026

Consulta [CHANGELOG.md](CHANGELOG.md) para el historial completo de cambios.

---

## Licencia y Copyright

© 2026 **Varohub-ilfuzza** — Todos los derechos reservados.

Este software es propiedad exclusiva de su autor. Queda prohibida su reproducción, distribución o modificación total o parcial sin autorización expresa por escrito del titular de los derechos.

---

*Creado: 7 de marzo de 2026*
