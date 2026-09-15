# Plan de Desarrollo: Controlador OSC para Behringer X32

Este documento describe los pasos para crear una aplicación en Flutter que controle una consola Behringer X32 a través del protocolo OSC, incluyendo un sistema de roles de usuario.

## Fase 0: Modo Demo y Simulación

- [ ] Implementar un "Modo Demo" en la app:
    - [ ] Añadir un switch/botón en la pantalla de conexión para activar el modo demo.
    - [ ] Si el modo demo está activo, simular la lógica OSC (envío y recepción de mensajes) sin conexión real.
    - [ ] Permitir probar la UI, mover faders y simular feedback como si estuviera conectada a una X32 real.
    - [ ] El modo demo debe funcionar igual que el modo real para facilitar el desarrollo y pruebas.

## Fase 1: Conectividad y Comunicación OSC Básica

- [ ] **Configurar el proyecto Flutter:**
    - [x] Añadir las dependencias necesarias para la comunicación UDP y el manejo de OSC (por ejemplo, el paquete `osc`).
- [ ] **Implementar la comunicación UDP:**
    - [x] Crear una clase de servicio para gestionar la conexión UDP.
    - [x] Implementar la capacidad de enviar datos a la dirección IP y puerto de la consola (10023).
    - [x] Implementar la escucha de paquetes UDP entrantes desde la consola.
- [ ] **Integrar el protocolo OSC:**
    - [ ] Crear una función para construir un paquete OSC a partir de una dirección (ej: `/ch/01/mix/fader`) y argumentos.
    - [ ] Implementar el envío de un mensaje OSC de prueba (p. ej., solicitar el estado de un canal).
    - [ ] Crear una función para parsear los paquetes OSC recibidos.
    - [ ] Implementar la recepción y decodificación de mensajes OSC.

## Fase 2: Interfaz de Usuario (UI) y Control Básico

- [ ] **Diseñar la interfaz de usuario:**
    - [x] Crear un widget para la configuración de la conexión (IP de la consola).
    - [x] Diseñar y construir los widgets básicos de control (Fader, Botón de Mute, etc.).
    - [ ] Crear una vista principal que muestre una sección de la mesa de mezclas (ej: 8 canales).
- [ ] **Vincular UI con OSC:**
    - [x] Conectar los eventos de los widgets (ej: mover un fader) para que envíen los mensajes OSC correspondientes.
    - [x] Actualizar el estado de la UI en tiempo real basándose en los mensajes OSC recibidos desde la consola (feedback).

## Fase 3: Sistema de Roles y Permisos

- [ ] **Definir la estructura de datos:**
    - [ ] Crear modelos de datos para `Usuario`, `Rol` y `Permiso`.
    - [ ] Diseñar una estructura que defina qué canales y buses puede controlar cada rol.
- [ ] **Implementar la lógica de roles:**
    - [ ] Crear una pantalla de "login" para seleccionar el rol.
    - [ ] Filtrar los widgets y controles visibles en la UI según los permisos del rol activo.
    - [ ] Bloquear el envío de mensajes OSC a direcciones no permitidas para el rol actual.

## Fase 3.1: Requerimientos avanzados de roles y UI

- [ ] Los usuarios seleccionan un rol localmente al iniciar la app (sin validación en backend).
- [ ] Roles predefinidos: transmisión, monitor, main.
- [ ] Permitir agregar y eliminar roles personalizados desde la app.
- [ ] Cada rol puede seleccionar un solo bus al que tiene acceso.
- [ ] Para cada bus, el rol puede elegir qué canales ver y el orden de los mismos.
- [ ] La UI de canales debe ser scrollable si hay más canales de los que caben en pantalla.
- [ ] La selección de rol y configuración de permisos debe ser persistente localmente (por ejemplo, usando almacenamiento local).

## Fase 4: Pruebas y Despliegue

- [ ] **Pruebas:**
    - [ ] Realizar pruebas de conexión con una consola X32 real o un simulador.
    - [ ] Verificar que el control bidireccional (UI -> Consola y Consola -> UI) funciona correctamente.
    - [ ] Probar la lógica de restricción de roles.
- [ ] **Despliegue:**
    - [ ] Preparar la aplicación para su compilación en las plataformas deseadas (Android, iOS, etc.).
