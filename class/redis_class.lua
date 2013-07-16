--~ auther: Angryfox Su
--~ date: 2013-06-26
--~ redis的封装类
module(..., package.seeall)

local redis = require "resty.redis" --加载redis库

local CACHE_TIME   = 3600
local SET_TIME_OUT = 1000

Redis_Class = class('Redis_Class')

function Redis_Class:initialize()

	self.host = "127.0.0.1"
	self.port = 6379
	self.max_idle_timeout = 1000*60
	self.pool_size = 1024

	self.red = redis:new() --实例化redis类
end

--~ 连接redis服务器
function Redis_Class:connect()
		
	local red = self.red
	red:set_timeout(SET_TIME_OUT) -- 1 sec
			 
	local ok, err = red:connect(self.host, self.port) --连接 redis 服务器
	if not ok then  --如果连接出错
		ngx.log(ngx.ERR, "failed to connect redis server: " .. err)
		return false, err
	end
	
	local times, err = red:get_reused_times()	
	if(not times or times == 0) then  --如果未从连接池获取数据
		ngx.log(ngx.NOTICE, "redis failed to use connection pool") 
	end

	return true, nil
end

function Redis_Class:close_conn()

	local red = self.red
	local ok, err = red:set_keepalive(self.max_idle_timeout, self.pool_size)
	if not ok then  --如果设置连接池出错
		ngx.log(ngx.ERR, "redis failed to set connect pool: " .. err) 
		end
end

--~ 设置缓存
function Redis_Class:setex(key, value, cache_time)

	local red = self.red
	local ok, err =self:connect()

	if not ok then  --如果连接出错
		return ok, err
		end
	
	local cache_time = cache_time or CACHE_TIME
	local ok, err = red:setex(key, cache_time, value)	
	if(not ok) then --如果插入失败
		self:close_conn()
		ngx.log(ngx.ERR, "failed to setex value: " .. err) 
		return false, err
	end
	self:close_conn()
	return true, nil
end

--~ 获取访问的key值
function Redis_Class:get(key) 

	local red = self.red
	local ok, err =self:connect()
	
	if not ok then  --如果连接出错
		return ok, err
	end

	local ok, err = red:get(key)

	if(not ok) then --如果发生错误
		ngx.log(ngx.ERR, "get value " ..err) 
		self:close_conn()
		return false, "get value error"
	end

	self:close_conn()
	return ok, nil
end

--~ 获得redis原生句柄
function Redis_Class:hander()
	local red = self.red
	local ok, err =self:connect()
	
	if not ok then  --如果连接出错
		return ok, err
	end
	return red, nil
end
