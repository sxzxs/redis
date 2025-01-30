#include <redisclient>

client := RedisClient("127.0.0.1", 6379)
ct := client.connect()

obj := {"_name293" : 100, "age": 20, "city": "浙江"}
reply := client.set("json", JSON.stringify(RedisClient))
loop 10
{
    reply := client.set(A_Index, A_Index)
}

reply := client.get("json")
MsgBox(reply.str())