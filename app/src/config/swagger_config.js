'use strict'
const apiConf = {
    routePrefix: '/taxonomy',
    exposeRoute: true,
    hideUntagged: true,
    swagger: {
      info: {
        title: 'Key to the Calanoid Copepods (Copkey)',
        description: '## Taxonomy API in **Copkey**\n' +
          '* This swagger-UI is just for trials of Copkey open API.\n' +
          '* Taxon data only contains the Calanoid species in Copkey database.',
        version: '1.0.0'
      },
      //externalDocs: {
      //  url: 'https://swagger.io',
      //  description: 'Find more info here'
      //},
      host: 'bio.odb.ntu.edu.tw',
      schemes: ['https'],
      consumes: ['application/json'],
      produces: ['application/json'],
    },
    uiConfig: {
      validatorUrl: null,
      docExpansion: 'list', //'full'
      deepLinking: false
    }
//} //https://github.com/fastify/fastify-swagger/issues/191
}
export default apiConf

