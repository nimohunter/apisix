--
-- Licensed to the Apache Software Foundation (ASF) under one or more
-- contributor license agreements.  See the NOTICE file distributed with
-- this work for additional information regarding copyright ownership.
-- The ASF licenses this file to You under the Apache License, Version 2.0
-- (the "License"); you may not use this file except in compliance with
-- the License.  You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--
local core          = require("apisix.core")
local math_random = math.random
local has_mod, apisix_ngx_client = pcall(require, "resty.apisix.client")


local plugin_name   = "proxy-mirror"
local schema = {
    type = "object",
    properties = {
        host = {
            type = "string",
            pattern = [[^http(s)?:\/\/[a-zA-Z0-9][-a-zA-Z0-9]{0,62}]]
                      .. [[(\.[a-zA-Z0-9][-a-zA-Z0-9]{0,62})+(:[0-9]{1,5})?$]],
        },
        sample_ratio = {
            type = "number",
            minimum = 0.00001,
            maximum = 1,
            default = 1,
        },
    },
    required = {"host"},
    minProperties = 1,
}

local _M = {
    version = 0.1,
    priority = 1010,
    name = plugin_name,
    schema = schema,
}


function _M.check_schema(conf)
    local ok, err = core.schema.check(schema, conf)
    if not ok then
        return false, err
    end

    return true
end


local function enable_mirror(ctx, host)
    ctx.var.upstream_mirror_host = host

    if has_mod then
        apisix_ngx_client.enable_mirror()
    end
end


function _M.rewrite(conf, ctx)
    core.log.info("proxy mirror plugin rewrite phase, conf: ", core.json.delay_encode(conf))

    ctx.var.upstream_host = ctx.var.host

    if not conf.sample_ratio or conf.sample_ratio == 1 then
        enable_mirror(ctx, conf.host)
    else
        local val = math_random()
        core.log.info("mirror request sample_ratio conf: ", conf.sample_ratio,
                                ", random value: ", val)
        if val < conf.sample_ratio then
            enable_mirror(ctx, conf.host)
        end
    end

end


return _M
