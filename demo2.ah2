#include <log>
#include <redisclient>

client := RedisClient()

client.redisConnect()

logger.info("start ")
logger.info("get >")
reply := client.redisCommandAllstr("GET", ["10"])
logger.info(reply.str())