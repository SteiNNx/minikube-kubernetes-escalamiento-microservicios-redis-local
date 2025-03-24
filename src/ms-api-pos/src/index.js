const express = require('express');
const redis = require('redis');
const app = express();
app.use(express.json());

const PORT = 3000;

const REDIS_IP = '172.29.123.16';
const REDIS_PORT = 30010;

/**
 * Crea y conecta un cliente Redis.
 * @returns {Promise<RedisClientType>} Cliente Redis conectado.
 */
async function createRedisClient() {
  const client = redis.createClient({
    socket: {
      host: REDIS_IP,
      port: REDIS_PORT
    }
  });
  await client.connect();
  console.log('Cliente Redis conectado.');
  return client;
}

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
 * @param {string} operation - Tipo de operación (ej. 'ANULACION', 'REVERSA', etc.)
 */
async function checkTransaction(idTransaction, operation) {
  const client = await createRedisClient();
  const key = `api-pos:${idTransaction}:${operation}`;
  const exists = await client.exists(key);

  if (exists) {
    await client.quit();
    throw new Error(`Transacción duplicada de ${operation}. Se ignora.`);
  }

  // Registra la transacción con un timeout de 180 segundos (3 minutos)
  await client.set(key, JSON.stringify({ status: 'in-progress' }), { EX: 180 });
  await client.quit();
  console.log(`Transacción ${idTransaction} registrada en Redis con timeout de 3 minutos para ${operation}.`);
}

// Endpoint para anulacion
app.post('/pagar_ms/anulacion', async (req, res) => {
  try {
    console.log('Body recibido (anulacion):', req.body);

    const idPago = req.body.idPago || "desconocido";

    // Verificar duplicidad de transacción para ANULACION
    await checkTransaction(idPago, 'ANULACION');

    // Fecha/hora actuales
    const nowLocal = new Date();
    const nowUTC = new Date(nowLocal.getTime() + nowLocal.getTimezoneOffset() * 60000);
    const localTimeFormat = formatCustomDate(nowLocal);
    const utcTimeFormat = formatCustomDate(nowUTC);
  
    const rrn = req.body.rrn || "688015368836";
    
    // Respuesta específica para la operación "anulación"
    const response = {
      code: "00",
      message: "Transaction processed succesfully",
      data: {
        opSvcRsHeader: {
          rqUID: idPago,
          operationType: "MREFUND",
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
          rrn,
          traceNumb: "654601",
          authIDResponse: req.body.auth_code || "958338",
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
    console.error("Error processing anulacion:", error);
    res.status(500).json({
      code: "99",
      message: "Error processing anulacion",
      error: error.message
    });
  }
});

// Endpoint para reversa
app.post('/pagar_ms/reversa', async (req, res) => {
  try {
    console.log('Body recibido (reversa):', req.body);

    const idPago = req.body.idPago || "desconocido";

    // Verificar duplicidad de transacción para REVERSA
    await checkTransaction(idPago, 'REVERSA');

    // Fecha/hora actuales
    const nowLocal = new Date();
    const nowUTC = new Date(nowLocal.getTime() + nowLocal.getTimezoneOffset() * 60000);
    const localTimeFormat = formatCustomDate(nowLocal);
    const utcTimeFormat = formatCustomDate(nowUTC);
  
    const rrn = req.body.rrn || "440771058924";
  
    // Respuesta específica para "reversa"
    const response = {
      code: "00",
      message: "Transaction processed succesfully",
      data: {
        opSvcRsHeader: {
          rqUID: idPago,
          operationType: "MPURCHASEREVERSAL",
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
          rrn,
          traceNumb: "853109",
          authIDResponse: "000000",
          responseCode: "00",
          transactionAmount: "000000000800",
          currencyCode: "152",
          acqInstID: "00000000000",
          posConditionCode: "00",
          cardEntryMode: req.body.datosTarjeta?.cardEntryMode || "071",
          track2: req.body.secureFields?.track2 || "",
          terminalId: req.body.idTerminal || "v0028ANn",
          retailerData: "59703837735300000000",
          invoiceData: "02055555000000000000000",
          pvtData: "00000000000000000000000000000000000000000000000000000000000000000000000000000"
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
    console.error("Error processing reversa:", error);
    res.status(500).json({
      code: "99",
      message: "Error processing reversa",
      error: error.message
    });
  }
});

// Endpoint para reversa_anulacion
app.post('/pagar_ms/reversa_anulacion', async (req, res) => {
  try {
    console.log('Body recibido (reversa_anulacion):', req.body);

    const idPago = req.body.idPago || "desconocido";

    // Verificar duplicidad de transacción para REVERSA_ANULACION
    await checkTransaction(idPago, 'REVERSA_ANULACION');

    // Fecha/hora actuales
    const nowLocal = new Date();
    const nowUTC = new Date(nowLocal.getTime() + nowLocal.getTimezoneOffset() * 60000);
    const localTimeFormat = formatCustomDate(nowLocal);
    const utcTimeFormat = formatCustomDate(nowUTC);
  
    const rrn = req.body.rrn || "688015368836";
  
    // Respuesta específica para "reversa_anulacion"
    const response = {
      code: "00",
      message: "Transaction processed succesfully",
      data: {
        opSvcRsHeader: {
          rqUID: idPago,
          operationType: "MREFUNDREVERSAL",
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
          rrn,
          traceNumb: "334387",
          authIDResponse: "000000",
          responseCode: "00",
          transactionAmount: "000000000800",
          currencyCode: "152",
          acqInstID: "00000000000",
          posConditionCode: "00",
          cardEntryMode: req.body.datosTarjeta?.cardEntryMode || "071",
          track2: req.body.secureFields?.track2 || "",
          terminalId: req.body.idTerminal || "v0028ANn",
          retailerData: "59703837735300000000",
          invoiceData: "02055555000000000000000",
          pvtData: "00000000000000000000000000000000000000000000000000000000000000000000000000000"
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
    console.error("Error processing reversa_anulacion:", error);
    res.status(500).json({
      code: "99",
      message: "Error processing reversa_anulacion",
      error: error.message
    });
  }
});

// Iniciamos el servidor
app.listen(PORT, () => {
  console.log(`Servidor escuchando en http://localhost:${PORT}`);
});
