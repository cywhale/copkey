const productionOrigins = new Set([
  'https://bio.odb.ntu.edu.tw',
  'https://api.odb.ntu.edu.tw',
  'https://eco.odb.ntu.edu.tw'
])

const developmentOrigins = new Set([
  ...productionOrigins,
  'https://192.168.2.29:3004',
  'https://localhost:3004',
  'https://127.0.0.1:3004'
])

export function createCorsOptions (req, nodeEnv = process.env.NODE_ENV || 'development') {
  const allowedOrigins = nodeEnv === 'production' ? productionOrigins : developmentOrigins
  const origin = req.headers.origin

  return {
    origin: Boolean(origin && allowedOrigins.has(origin)),
    credentials: false,
    preflight: true,
    preflightContinue: false,
    methods: ['GET', 'POST', 'OPTIONS'],
    allowedHeaders: ['Origin', 'X-Requested-With', 'Content-Type', 'Accept', 'Keep-Alive', 'User-Agent',
      'Cache-Control', 'Authorization', 'DNT', 'X-PINGOTHER', 'Range'],
    exposedHeaders: ['Content-Range'],
    maxAge: 86400
  }
}
