#include <redisclient>
client := RedisClient()
client.connect()

client.appandCommand("SET", "key1", "value1")
client.appandCommand("SET", "key2", "value2")
client.appandCommand("SET", "key3", "value3")

client.getReply(&reply)
client.getReply(&reply)
client.getReply(&reply)

client.appandCommand("GET", "key1")
client.appandCommand("GET", "key2")
client.appandCommand("GET", "key3")
client.getReply(&reply)
MsgBox(reply.str())

client.getReply(&reply)
MsgBox(reply.str())

client.getReply(&reply)
MsgBox(reply.str())