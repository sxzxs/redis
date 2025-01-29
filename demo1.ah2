#include <redisclient>

client := RedisClient("127.0.0.1", 6379)
ct := client.redisConnect()

obj := {"_name293" : 100, "age": 20, "city": "浙江"}
reply := client.redisCommandAllstr("SET", ["json", JSON.stringify(RedisClient)])
loop 10
{
    reply := client.redisCommandAllstr("SET", [A_Index, A_Index])
}

reply := client.redisCommandAllstr("GET", ["json"])
MsgBox(reply.str())