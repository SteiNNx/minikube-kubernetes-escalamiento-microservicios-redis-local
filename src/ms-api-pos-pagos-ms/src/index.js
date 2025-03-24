const express = require('express');
const redis = require('redis');

const app = express();
app.use(express.json());

const PORT = 3000;

const REDIS_IP = '172.29.123.16';
const REDIS_PORT = 30010;

/**
 * Función para formatear fechas al estilo "YYYY-MM-DD:HH:mm:ss.mmm"
 * @param {Date} date
 * @returns {string}
 */
function formatCustomDate(date) {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    const hours = String(date.getHours()).padStart(2, '0');
    const minutes = String(date.getMinutes()).padStart(2, '0');
    const seconds = String(date.getSeconds()).padStart(2, '0');
    const millis = String(date.getMilliseconds()).padStart(3, '0');
    return `${year}-${month}-${day}:${hours}:${minutes}:${seconds}.${millis}`;
}

/**
 * Función asíncrona que conecta a Redis, verifica que no exista la transacción
 * y, de no existir, la registra con un timeout de 3 minutos.
 * Si ya existe, lanza un error.
 * @param {string} idTransaction - Identificador de la transacción.
 */
async function checkPayment(idTransaction) {
    // Crear cliente Redis y conectarlo
    const redisClient = redis.createClient({
        socket: {
            host: REDIS_IP,
            port: REDIS_PORT
        }
    });
    await redisClient.connect();

    const key = `api-pos:${idTransaction}:PAGO`;
    const exists = await redisClient.exists(key);

    if (exists) {
        await redisClient.quit();
        throw new Error("Transacción duplicada de PAGO. Se ignora.");
    }

    // Si no existe, se registra la transacción con un timeout de 180 segundos (3 minutos)
    await redisClient.set(key, JSON.stringify({ status: 'in-progress' }), {
        EX: 180
    });

    await redisClient.quit();
    console.log(`Transacción ${idTransaction} registrada en Redis con timeout de 3 minutos.`);
}

// Endpoint para procesar pago
app.post('/pagar_ms/pagar', async (req, res) => {
    try {
        console.log('Body recibido:', req.body);

        // Obtener id de transacción (o asignar un valor por defecto)
        const idTransaction = req.body.idPago || "desconocido";

        // Ejecutar checkPayment: se conectará a Redis, verificará e insertará si procede.
        await checkPayment(idTransaction);

        // Si checkPayment no lanza error, se continúa con el procesamiento:
        const nowLocal = new Date();
        const nowUTC = new Date(nowLocal.getTime() + nowLocal.getTimezoneOffset() * 60000);
        const localTimeFormat = formatCustomDate(nowLocal);
        const utcTimeFormat = formatCustomDate(nowUTC);

        // Construir la respuesta (manteniendo la lógica original)
        const response = {
            code: "00",
            message: "Transaction processed succesfully",
            data: {
                opSvcRsHeader: {
                    rqUID: idTransaction,
                    operationType: "MPURCHASE",
                    statusCode: "00",
                    severity: "SUCCESS",
                    statusDescription: "Transaction approved",
                    serverDateTime: localTimeFormat,
                    customerLanguagePref: "en-us",
                    clientAppName: "mPOS",
                    clientAppOrg: req.body.datosComercio?.clientAppOrg || "prueba",
                    clientAppVersion: "1"
                },
                opSvcRsBody: {
                    rrn: req.body.rrn || "000000000000",
                    traceNumb: "406655",
                    authIDResponse: "958338",
                    responseCode: "00",
                    transactionAmount: "000000000800",
                    currencyCode: "152",
                    acqInstID: "00000000000",
                    captureDate: "0321",
                    settlementDate: "0321",
                    MCC: req.body.datosComercio?.MCC || "5411",
                    cardEntryMode: req.body.datosTarjeta?.cardEntryMode || "071",
                    track2: req.body.secureFields?.track2 || "",
                    terminalId: req.body.idTerminal || "v0028ANn",
                    cardIssRespData: "00000000000",
                    additionalInfo: "",
                    invoiceData: req.body.datosTarjeta?.invoiceData || "55555",
                    pvtData: "0000000000000000000000000000000000000000000000000000000000000000000000000000000-                                       000000000000000000000000000000000000000000000000000000000000000000000000000000000"
                },
                responseBackHours: {
                    fecha: localTimeFormat,
                    fechaUTC: utcTimeFormat,
                    fechaPOS: req.body.localTimeFormat || localTimeFormat,
                    fechaPOSUTC: req.body.UTCTimeFormat || utcTimeFormat
                }
            }
        };

        res.json(response);
    } catch (error) {
        console.error("Error processing payment:", error);
        res.status(500).json({
            code: "99",
            message: "Error processing payment",
            error: error.message
        });
    }
});

// Iniciar el servidor en el puerto 3000
app.listen(PORT, () => {
    console.log(`Servidor escuchando en http://localhost:${PORT}`);
});
