//var log;
export function logger(fastify, opts, done) {
  //if (!log) {
  const log = fastify.log
  //}
  done()
  return log
}

export default logger
