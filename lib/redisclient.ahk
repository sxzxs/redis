#Requires AutoHotkey v2.0 

REDIS_ERR := -1
REDIS_OK :=0

/* When an error occurs, the err flag in a context is set to hold the type of
 * error that occurred. REDIS_ERR_IO means there was an I/O error and you
 * should use the "errno" variable to find out what is wrong.
 * For other values, the "errstr" field will hold a description. */
REDIS_ERR_IO := 1
REDIS_ERR_EOF := 3
REDIS_ERR_PROTOCOL := 4
REDIS_ERR_OOM := 5
REDIS_ERR_TIMEOUT := 6
REDIS_ERR_OTHER := 2

REDIS_REPLY_STRING := 1
REDIS_REPLY_ARRAY := 2
REDIS_REPLY_INTEGER := 3
REDIS_REPLY_NIL := 4
REDIS_REPLY_STATUS := 5
REDIS_REPLY_ERROR := 6
REDIS_REPLY_DOUBLE := 7
REDIS_REPLY_BOOL := 8
REDIS_REPLY_MAP := 9
REDIS_REPLY_SET := 10
REDIS_REPLY_ATTR := 11
REDIS_REPLY_PUSH := 12
REDIS_REPLY_BIGNUM := 13
REDIS_REPLY_VERB := 14

redisStr(str, encoding := "UTF-8")
{
    buf := Buffer(StrPut(str, encoding))
    StrPut(str, buf, encoding)
    return buf
}

class RedisReply
{
    __New(ptr) => this.ptr := ptr

    __Delete()
    {
        RedisClient.sfreeReplyObject(this.ptr)
    }

    type() => NumGet(this.ptr, 0, 'int')

    interger() => NumGet(this.ptr, 8, 'int64')

    dval() => NumGet(this.ptr, 16, 'int')

    str()
    {
        str :=NumGet(this.ptr, 32, "ptr")
        return StrGet(str, "UTF-8")
    }
}

class RedisContext
{
    __New(ptr) => this.ptr := ptr
    __Delete() => RedisClient.sredisFree(this.ptr)
}

class RedisClient
{
    __New(host := "127.0.0.1", port := 6379, db := 0) 
    {
        this.host := host
        this.port := port
        this.db := db
    }

    StrBuf(str, encoding := "UTF-8")
    {
        buf := Buffer(StrPut(str, encoding))
        StrPut(str, buf, encoding)
        return buf
    }

    connect()
    {
        ct := DllCall(RedisClient.redisConnect, "ptr", this.StrBuf(this.host), "int", this.port, "ptr")
        ct := RedisContext(ct)
        this.ct := ct
        return ct
    }

    get(args*) => this.command("GET", args*)

    set(args*) => this.command("SET", args*)

    command(command, args*)
    {
        formate := command " "
        for k, v in args
            formate .= "%s "

        dllargs := []
        for k, v in args
            dllargs.Push("ptr"), dllargs.Push(this.StrBuf(v))

        dllargs.Push("cdecl ptr")

        ptr := DllCall(RedisClient.redisCommand, "Ptr", this.ct.ptr, "ptr", this.StrBuf(formate), dllargs*)
        return RedisReply(ptr)
    }

    appandCommand(command, args*)
    {
        formate := command " "
        for k, v in args
            formate .= "%s "

        dllargs := []
        for k, v in args
            dllargs.Push("ptr"), dllargs.Push(this.StrBuf(v))

        dllargs.Push("int")
        return DllCall(RedisClient.redisAppendCommand, "Ptr", this.ct.ptr, "ptr", this.StrBuf(formate), dllargs*)
    }

    getReply(&reply)
    {
        bf := Buffer(8)
        rtn := DllCall(RedisClient.redisGetReply, "Ptr", this.ct.ptr, "ptr", bf, "int")
        reply := RedisReply(NumGet(bf, 0, 'ptr'))
        return rtn
    }

    static sfreeReplyObject(reply) => DllCall(RedisClient.freeReplyObject, "Ptr", reply)

    static sredisFree(c) => DllCall(RedisClient.redisFree, "Ptr", c)

    static module := Map()

	static __New()
	{
		SplitPath(A_LineFile, , &dir)
		path := ""
		lib_path := dir
		if (A_IsCompiled)
		{
			path := (A_PtrSize == 4) ? A_ScriptDir . "\lib\dll_32\" : A_ScriptDir . "\lib\dll_64\"
			lib_path := A_ScriptDir . "\lib"
		}
		else
		{
			path := (A_PtrSize == 4) ? dir . "\dll_32\" : dir . "\dll_64\"
		}
		DllCall("SetDllDirectory", "Str", path)
		this.lib := DllCall("LoadLibrary", "Str", 'hiredis.dll', "ptr")
        this.module := RedisClient.get_module_exports(this.lib, this)
	}

	static GPA(function) => DllCall("GetProcAddress", 'Ptr', this.lib, 'AStr', function, 'Ptr')

    static get_module_exports(mod, t := {}) 
    {
        if !mod
            mod := DllCall('GetModuleHandleW', 'ptr', 0, 'ptr')
        else if (DllCall('GetModuleFileNameW', 'ptr', mod, 'ptr*', 0, 'uint', 1), A_LastError = 126)
            Throw OSError()
        data_directory_offset := NumGet(mod, 60, 'uint') + 104 + A_PtrSize * 4
        entry_export := mod + NumGet(mod, data_directory_offset, 'uint')
        entry_export_end := entry_export + NumGet(mod, data_directory_offset + 4, 'uint')
        func_tbl_offset := NumGet(entry_export, 0x1c, 'uint')
        name_tbl_offset := NumGet(entry_export, 0x20, 'uint')
        ordinal_tbl_offset := NumGet(entry_export, 0x24, 'uint')
        exports := Map()
        loop NumGet(entry_export, 0x18, 'uint') 
        {
            ordinal := NumGet(mod, ordinal_tbl_offset, 'ushort')
            fn_ptr := mod + NumGet(mod, func_tbl_offset + ordinal * 4, 'uint')
            if entry_export <= fn_ptr && fn_ptr < entry_export_end 
            {
                fn_name := StrSplit(StrGet(fn_ptr, 'cp0'), '.')
                fn_ptr := DllCall('GetProcAddress', 'ptr', DllCall('GetModuleHandle', 'str', fn_name[1], 'ptr'), 'astr', fn_name[2], 'ptr')
            }
            exports[StrGet(mod + NumGet(mod, name_tbl_offset, 'uint'), 'cp0')] := fn_ptr
            t.%StrGet(mod + NumGet(mod, name_tbl_offset, 'uint'), 'cp0')% := fn_ptr
            name_tbl_offset += 4, ordinal_tbl_offset += 2
        }
        return exports
    }
}