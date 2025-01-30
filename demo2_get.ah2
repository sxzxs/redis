#include <redisclient>

client := RedisClient()
ct := client.connect()

reply := client.get("10")
MsgBox(reply.str())