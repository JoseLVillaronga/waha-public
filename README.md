# WAHA Secure API
![ChatGPT Image 5 may 2025, 20_26_52](https://github.com/user-attachments/assets/13847c92-2f8c-47e9-b2a5-6c1dd5560742)

Una interfaz segura para la API WAHA local que proporciona autenticación mediante clave API de 256 bits.

## Descripción General

WAHA Secure API es una interfaz segura que actúa como intermediario entre aplicaciones externas e Internet y la API WAHA local. Proporciona una capa de autenticación mediante una clave API de 256 bits para proteger el acceso a la funcionalidad de envío de mensajes de WhatsApp.

## Requisitos

- Python 3.8 o superior
- API WAHA funcionando en la red local
- Conexión a Internet (para la API externa)

## Configuración

1. Asegúrate de tener Python 3.8+ instalado
2. Configura las variables de entorno en el archivo `.env`:
   ```
   PUB_WAHA_KEY=tu_clave_api_de_256_bits
   PUB_WAHA_PORT=22100
   WAHA_API_URL=http://tu_ip_local:3000/api
   ```

Reemplaza:
- `tu_clave_api_de_256_bits` con una clave segura de 256 bits (puedes generar una con herramientas como OpenSSL)
- `tu_ip_local` con la dirección IP donde se ejecuta la API WAHA

Ejemplo de generación de clave API con OpenSSL:
```bash
openssl rand -hex 32
```

## Instalación

```bash
# Crear entorno virtual (opcional pero recomendado)
python -m venv venv
source venv/bin/activate  # En Windows: venv\Scripts\activate

# Instalar dependencias
pip install -r requirements.txt
```

## Ejecución

### Método 1: Ejecución manual

```bash
# Usando el script de inicio
chmod +x start_server.sh  # Solo la primera vez
./start_server.sh

# O directamente con Python
python main.py
```

El servidor se iniciará en `http://0.0.0.0:22100` (o el puerto que hayas configurado).

### Método 2: Instalación como servicio systemd

Para instalar la API como un servicio del sistema que se inicie automáticamente al arrancar:

```bash
# Hacer ejecutable el script de instalación
chmod +x install_service.sh

# Ejecutar el script de instalación
./install_service.sh
```

El script realizará las siguientes acciones:
1. Verificará que todos los archivos necesarios existan
2. Creará un entorno virtual si no existe
3. Instalará el servicio systemd
4. Configurará el servicio para iniciarse automáticamente al arrancar el sistema

Una vez instalado, puedes gestionar el servicio con los siguientes comandos:

```bash
# Iniciar el servicio
sudo systemctl start waha-secure-api.service

# Detener el servicio
sudo systemctl stop waha-secure-api.service

# Ver el estado del servicio
sudo systemctl status waha-secure-api.service

# Ver los logs del servicio
sudo journalctl -u waha-secure-api.service -f
```

Para desinstalar el servicio:

```bash
# Hacer ejecutable el script de desinstalación (si no lo está)
chmod +x uninstall_service.sh

# Ejecutar el script de desinstalación
./uninstall_service.sh
```

## Uso de la API

### Autenticación

Todas las solicitudes a la API deben incluir el encabezado `X-API-Key` con la clave API configurada.

### Endpoints

#### Enviar mensaje de texto

**Endpoint:** `POST /api/sendText`

**Headers:**
- `Content-Type: application/json`
- `X-API-Key: tu_clave_api_de_256_bits`

**Cuerpo de la solicitud:**
```json
{
  "chatId": "5491122334455@c.us",
  "text": "Mensaje de prueba",
  "reply_to": null,
  "linkPreview": true,
  "linkPreviewHighQuality": false,
  "session": "default"
}
```

**Parámetros:**
- `chatId` (obligatorio): ID del chat de WhatsApp (número@c.us para chats individuales)
- `text` (obligatorio): Texto del mensaje a enviar
- `reply_to` (opcional): ID del mensaje al que se responde
- `linkPreview` (opcional): Habilitar vista previa de enlaces (por defecto: true)
- `linkPreviewHighQuality` (opcional): Usar vista previa de alta calidad (por defecto: false)
- `session` (opcional): Nombre de la sesión (por defecto: "default")

**Respuesta exitosa:**
```json
{
  "success": true,
  "message": "Message sent successfully",
  "data": {
    "message_id": "true_5491122334455@c.us_ABC123DEF456GHI789_out"
  }
}
```

**Respuesta de error:**
```json
{
  "success": false,
  "message": "Error: [descripción del error]",
  "data": null
}
```

#### Verificar estado del servicio

**Endpoint:** `GET /health`

**Respuesta:**
```json
{
  "status": "healthy"
}
```

## Ejemplos de Uso

### cURL

```bash
curl -X 'POST' \
  'http://tu_servidor:22100/api/sendText' \
  -H 'accept: application/json' \
  -H 'X-API-Key: abc123def456ghi789jkl012mno345pqr678stu901vwx234yz' \
  -H 'Content-Type: application/json' \
  -d '{
  "chatId": "5491122334455@c.us",
  "text": "Mensaje de prueba desde cURL",
  "linkPreview": true,
  "session": "default"
}'
```

### JavaScript (Node.js)

```javascript
const axios = require('axios');

async function sendWhatsAppMessage() {
  try {
    const response = await axios.post('http://tu_servidor:22100/api/sendText', {
      chatId: '5491122334455@c.us',
      text: 'Mensaje de prueba desde Node.js',
      linkPreview: true,
      session: 'default'
    }, {
      headers: {
        'X-API-Key': 'abc123def456ghi789jkl012mno345pqr678stu901vwx234yz',
        'Content-Type': 'application/json'
      }
    });

    console.log('Respuesta:', response.data);

    if (response.data.success) {
      console.log('Mensaje enviado correctamente. ID:', response.data.data.message_id);
    } else {
      console.error('Error al enviar mensaje:', response.data.message);
    }
  } catch (error) {
    console.error('Error en la solicitud:', error.message);
  }
}

sendWhatsAppMessage();
```

### PHP

```php
<?php
// Configuración
$apiUrl = 'http://tu_servidor:22100/api/sendText';
$apiKey = 'abc123def456ghi789jkl012mno345pqr678stu901vwx234yz';

// Datos del mensaje
$phoneNumber = '5491122334455'; // Sin el signo +
$message = 'Mensaje de prueba desde PHP';

// Preparar datos para la solicitud
$data = [
    'chatId' => $phoneNumber . '@c.us',
    'text' => $message,
    'linkPreview' => true,
    'session' => 'default'
];

// Inicializar cURL
$curl = curl_init();

// Configurar opciones de cURL
curl_setopt_array($curl, [
    CURLOPT_URL => $apiUrl,
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_ENCODING => '',
    CURLOPT_MAXREDIRS => 10,
    CURLOPT_TIMEOUT => 30,
    CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
    CURLOPT_CUSTOMREQUEST => 'POST',
    CURLOPT_POSTFIELDS => json_encode($data),
    CURLOPT_HTTPHEADER => [
        'Content-Type: application/json',
        'X-API-Key: ' . $apiKey
    ],
]);

// Ejecutar la solicitud
$response = curl_exec($curl);
$err = curl_error($curl);

// Cerrar cURL
curl_close($curl);

// Procesar la respuesta
if ($err) {
    echo "Error cURL: " . $err;
} else {
    $responseData = json_decode($response, true);

    if ($responseData['success']) {
        echo "Mensaje enviado correctamente. ID: " . $responseData['data']['message_id'];
    } else {
        echo "Error al enviar mensaje: " . $responseData['message'];
    }
}
?>
```

## Documentación de la API

Una vez que el servidor esté en funcionamiento, puedes acceder a la documentación interactiva de la API en:

- Swagger UI: http://localhost:22100/docs
- ReDoc: http://localhost:22100/redoc

## Consideraciones de Seguridad

1. **Protección de la clave API**: Mantén tu clave API segura y no la compartas públicamente.
2. **HTTPS**: Considera configurar HTTPS para proteger las comunicaciones entre tus aplicaciones y la API.
3. **Firewall**: Configura reglas de firewall para limitar el acceso al servidor de la API.

## Solución de Problemas

### El mensaje no se envía

1. Verifica que la API WAHA local esté funcionando correctamente.
2. Comprueba que la URL de la API WAHA en el archivo `.env` sea correcta.
3. Asegúrate de que el formato del `chatId` sea correcto (número@c.us).

### Error de autenticación

1. Verifica que estás utilizando la clave API correcta en el encabezado `X-API-Key`.
2. Comprueba que la clave API en el archivo `.env` coincida con la que estás utilizando en las solicitudes.
