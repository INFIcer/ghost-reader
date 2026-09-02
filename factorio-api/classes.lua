-- classes.lua
-- 全部 Factorio 运行时 Lua* 类（由官方 API 数据生成）。
-- 成员已含继承展平；方法用 :name(...) 定义以支持自动补全与跳转。
-- 每个类/字段/方法均带官方文档说明，悬停即可查看用法。

--- 用于覆盖默认 AI 行为的设置集合。
---@class LuaAISettings
---@field allow_destroy_when_commands_fail boolean 若启用，反复无法成功执行命令的单位将被销毁。
---@field allow_try_return_to_spawner boolean 若启用，无事可做的单位将尝试返回产卵器（spawner）。
---@field do_separation boolean 若启用，单位将尝试与附近的友方单位分开。
---@field help string 此对象支持的所有方法和属性。
---@field path_resolution_modifier boolean 寻路分辨率修正系数。
---@field valid boolean (只读) 此对象是否有效？
LuaAISettings = {}

--- 蓄电器（accumulator）的控制行为。
---@class LuaAccumulatorControlBehavior
---@field entity LuaEntity (只读) 此控制行为所属的实体。
---@field help string 此对象支持的所有方法和属性。
---@field output_signal table
---@field type defines.control_behavior.type (只读) 此控制行为的具体类型。
---@field valid boolean (只读) 此对象是否有效？
LuaAccumulatorControlBehavior = {}

--- 参数
--- wire :: defines.wire_type：与此实体相连网络的电线颜色。
--- circuit_connector :: defines.circuit_connector_id（可选）：要获取电路网络的连接器。
--- 对于拥有多个电路网络连接器的实体必须指定。
--- 返回值
--- 电路网络，或 nil。
---@return LuaCircuitNetwork result
---@param circuit_connector defines.circuit_connector_id? 要获取其电路网络的连接器。
对于拥有多个电路网络连接器的实体，必须指定此项。
---@param wire defines.wire_type 连接到此实体的网络的导线颜色。
function LuaAccumulatorControlBehavior:get_circuit_network(circuit_connector, wire) end

--- 弹药类别（ammo category）的原型。
---@class LuaAmmoCategoryPrototype
---@field bonus_gui_order string (只读)
---@field help string 此对象支持的所有方法和属性。
---@field localised_description table (只读)
---@field localised_name table (只读)
---@field name string (只读) 此原型的名称。
---@field order string (只读) 此原型的排序字符串。
---@field valid boolean (只读) 此对象是否有效？
LuaAmmoCategoryPrototype = {}

--- 算术组合器（arithmetic combinator）的控制行为。
---@class LuaArithmeticCombinatorControlBehavior
---@field entity LuaEntity (只读) 此控制行为所属的实体。
---@field help string 此对象支持的所有方法和属性。
---@field parameters table 算术组合器参数。 注意： parameters 可以为 nil，以清除参数。
---@field signals_last_tick table[] (只读) 此组合器上一 tick 发送的电路网络信号。
---@field type defines.control_behavior.type (只读) 此控制行为的具体类型。
---@field valid boolean (只读) 此对象是否有效？
LuaArithmeticCombinatorControlBehavior = {}

--- 参数
--- wire :: defines.wire_type：与此实体相连网络的电线颜色。
--- circuit_connector :: defines.circuit_connector_id（可选）：要获取电路网络的连接器。
--- 对于拥有多个电路网络连接器的实体必须指定。
--- 返回值
--- 电路网络，或 nil。
---@return LuaCircuitNetwork result
---@param circuit_connector defines.circuit_connector_id? 要获取其电路网络的连接器。
对于拥有多个电路网络连接器的实体，必须指定此项。
---@param wire defines.wire_type 连接到此实体的网络的导线颜色。
function LuaArithmeticCombinatorControlBehavior:get_circuit_network(circuit_connector, wire) end

--- 获取此组合器行为上一 tick 发送的特定信号的值，若该信号不存在则返回 nil。
--- 参数
--- signal :: SignalID：要获取的信号。
--- 返回值
--- 信号值；若无则返回 nil。
---@return integer count
---@param signal table 要获取的信号。
function LuaArithmeticCombinatorControlBehavior:get_signal_last_tick(signal) end

--- 自动放置控制（autoplace control）的原型。
---@class LuaAutoplaceControlPrototype
---@field category string (只读) 此原型的类别名称。
---@field control_order string (只读)
---@field help string 此对象支持的所有方法和属性。
---@field localised_description table (只读)
---@field localised_name table (只读)
---@field name string (只读) 此原型的名称。
---@field order string (只读) 此原型的排序字符串。
---@field richness boolean (只读)
---@field valid boolean (只读) 此对象是否有效？
LuaAutoplaceControlPrototype = {}

--- 注册事件处理器的入口点。可通过名为 script 的全局对象访问。
---@class LuaBootstrap
---@field mod_name string (只读) 使用此对象的环境所属模组的名称。
LuaBootstrap = {}

--- 生成一个新的唯一事件 ID。
--- 返回值
--- 新的事件 ID。
---@return integer count
function LuaBootstrap:generate_event_name(...) end

--- 查找某个事件的事件处理器。
--- 参数
--- event :: uint：要获取处理器的事件标识符。
--- 返回值
--- 当前注册为该事件处理器的函数引用。
---@param event integer 要为其获取处理函数的事件标识符。
function LuaBootstrap:get_event_handler(event) end

--- 获取模组事件顺序。
--- type(string)：类型为字符串。
function LuaBootstrap:get_event_order(...) end

--- 注册一个在模组配置变更时运行的函数。
--- 只要游戏版本变化、原型变化、启动模组设置变化，或任何模组版本变化（包括添加或移除模组），此函数都会被调用。
--- 参数
--- f :: function(ConfigurationChangedData)
--- 此事件的处理函数。传入 nil 将注销该处理器。
---@param f fun(ConfigurationChangedData) 此事件的处理函数。传入 nil 将注销该处理函数。
function LuaBootstrap:on_configuration_changed(f) end

--- 注册一个在某个或某些事件发生时运行的处理函数。
--- 参数
--- event :: defines.events、defines.events 数组或 string：要调用处理器的事件或自定义输入名称。
--- f :: function(Event)：要运行的处理函数。传入 nil 将注销该处理器。处理器将收到一个表，其中包含键 name（类型为 defines.events），指明它被调用处理的事件名称，以及 tick，指明事件创建时的 tick。该表还会根据事件类型包含其他字段。有关这些附加字段的列表，请参阅 Factorio 事件列表。
--- 注意： 由 LuaBootstrap::raise_event 引发的事件除上述属性外还包含 mod_name。
---@param event defines.events | defines.events[] | string 要调用处理函数的事件或自定义输入（custom-input）名称。
---@param f fun(Event) 要运行的处理函数。传入 nil 将注销该处理函数。处理函数会收到一个表，其中包含键 name（类型为 [defines.events]），用于指定它被调用时所处理的事件名称；以及键 tick，用于指定事件创建的时间。根据事件类型的不同，该表还可能包含其他字段。有关这些附加字段的列表，请参阅 Factorio 事件列表。
function LuaBootstrap:on_event(event, f) end

--- 注册一个在模组初始化时运行的回调函数。
--- 在创建新存档时调用一次，或在加载一个此前不包含此模组的存档文件时调用一次。
--- 此回调总是在其他事件处理器之前被调用，用于设置模组在其整个生命周期中使用的初始值。
--- 参数
--- f :: function()：要调用的函数。传入 nil 将注销该处理器。
---@param f fun() 要调用的函数。传入 nil 将注销该处理函数。
function LuaBootstrap:on_init(f) end

--- 注册一个在模组加载时运行的函数。
--- 每次加载存档文件时都会调用此函数，但模组被加载进一个此前不包含它的存档时除外。
--- 此外，在多人游戏中连接到任何其他游戏时也会调用此函数，且绝不应更改游戏状态。此函数仅用于以下 3 个特定目的：
--- - 重新注册条件事件处理器
--- - 重新设置元表（meta table）
--- - 为存储在全局表中的表创建局部引用
--- 在所有其他情况下，应使用 LuaBootstrap::on_init、LuaBootstrap::on_configuration_changed 或迁移脚本。
--- 在加载存档文件时执行任何其他逻辑都可能导致回放损坏，并在模组用于多人游戏时引发不同步（desync）问题。
--- 参数
--- f :: function()：要调用的函数。传入 nil 将注销该处理器。
--- 注意： 在此事件中 LuaGameScript 和 LuaRendering 不可用。
---@param f fun() 要调用的函数。传入 nil 将注销该处理函数。
function LuaBootstrap:on_load(f) end

--- 注册一个在每隔 n tick 运行时执行的处理函数。当游戏处于 tick 0 时，它会触发所有已注册的处理器。
--- 参数
--- tick :: uint 或 uint 数组：要调用处理器的第 n tick。传入 nil 将注销所有 nth-tick 处理器。
--- f :: function(NthTickEvent)：要运行的处理函数。传入 nil 将注销所提供 tick 的处理器。
---@param f fun(NthTickEvent) 要运行的处理函数。传入 nil 将注销针对所提供 tick 的处理函数。
---@param tick integer | integer[] 要调用处理函数的第 N tick（nth-tick）。传入 nil 将注销所有 nth-tick 处理函数。
function LuaBootstrap:on_nth_tick(f, tick) end

--- 引发一个事件。
--- 参数
--- event :: uint：要引发的事件 ID。
--- table：包含附加数据的表。此表将被传递给事件处理器。
---@param event integer 要触发的事件 ID。
---@param _table table 包含附加数据的表。该表将被传递给事件处理函数。
function LuaBootstrap:raise_event(event, _table) end


--- 注册一个函数，在游戏正常关闭时调用。
---@param handler fun()
function LuaBootstrap:on_shutdown(handler) end

--- 对特定 LuaEntity 或 LuaEquipment 所拥有的燃烧器（burner）能源的引用。
---@class LuaBurner
---@field burnt_result_inventory LuaInventory (只读) 燃烧产物（burnt result）物品栏。
---@field currently_burning LuaItemPrototype 注意： 写入时会自动处理修正 LuaBurner::remaining_burning_fuel。
---@field fuel_categories table<string, boolean> (只读) 此燃烧器使用的燃料类别。 注意： 字典中的值没有意义，只是为了便于查找而采用字典类型。
---@field heat number
---@field heat_capacity number (只读)
---@field help string 此对象支持的所有方法和属性。
---@field inventory LuaInventory (只读) 燃料物品栏。
---@field owner LuaEntity | LuaEquipment (只读) 此燃烧器能源的拥有者。
---@field remaining_burning_fuel number 注意： 若未设置 LuaBurner::currently_burning，写入将静默地不做任何事。
---@field valid boolean (只读) 此对象是否有效？
LuaBurner = {}

--- 燃烧器能源的原型。
---@class LuaBurnerPrototype
---@field burnt_inventory_size integer (只读)
---@field effectivity number (只读)
---@field emissions number (只读)
---@field fuel_categories table<string, boolean> (只读) 注意： 字典中的值没有意义，只是为了便于查找而采用字典类型。
---@field fuel_inventory_size integer (只读)
---@field help string 此对象支持的所有方法和属性。
---@field light_flicker table (只读) 此燃烧器原型的灯光闪烁（light flicker）定义（若有）。 包含以下字段的表： minimum_intensity :: float（最小强度） maximum_intensity :: float（最大强度） derivation_change_frequency :: float（偏移变化频率） derivation_change_deviation :: float（偏移变化偏差） border_fix_speed :: float（边界修正速度） minimum_light_size :: float（最小光照尺寸） light_intensity_to_size_coefficient :: float（光强与尺寸的转换系数） color :: Color（颜色）
---@field render_no_network_icon boolean (只读)
---@field render_no_power_icon boolean (只读)
---@field smoke table[] (只读) 此燃烧器原型的烟雾源（smoke source）（若有）。 每个元素是一个表： name :: string（名称） frequency :: double（频率） offset :: double（偏移） position :: Vector（可选）（位置） north_position :: Vector（可选）（北向位置） east_position :: Vector（可选）（东向位置） south_position :: Vector（可选）（南向位置） west_position :: Vector（可选）（西向位置） deviation :: Position（可选）（偏差） starting_frame_speed :: uint16（起始帧速度） starting_frame_speed_deviation :: double（起始帧速度偏差） starting_frame :: uint16（起始帧） starting_frame_deviation :: double（起始帧偏差） slow_down_factor :: uint8（减速因子） height :: float（高度） height_deviation :: float（高度偏差） starting_vertical_speed :: float（起始垂直速度） starting_vertical_speed_deviation :: float（起始垂直速度偏差） vertical_speed_slowdown :: float（垂直速度衰减）
---@field valid boolean (只读) 此对象是否有效？
LuaBurnerPrototype = {}

--- 区块迭代器（chunk iterator）可用于遍历某个地表（surface）的区块坐标。
---@class LuaChunkIterator
---@field help string 此对象支持的所有方法和属性。
---@field valid boolean (只读) 此对象是否有效？
LuaChunkIterator = {}

--- 获取下一个区块位置或 nil，并使迭代器前进。
---@return table result
function LuaChunkIterator:___(...) end

--- 与给定实体、连接器和电线类型相关联的电路网络。
---@class LuaCircuitNetwork
---@field circuit_connector_id defines.circuit_connector_id (只读) 此网络来源的关联实体上的电路连接器 ID。
---@field connected_circuit_count integer (只读) 连接到该网络的电路数量。
---@field entity LuaEntity (只读) 与此电路网络引用相关联的实体。
---@field help string 此对象支持的所有方法和属性。
---@field network_id integer (只读) 电路网络的 ID。
---@field signals table[] (只读) 上一 tick 的电路网络信号。若没有信号则为 nil。
---@field valid boolean (只读) 此对象是否有效？
---@field wire_type defines.wire_type (只读) 此网络关联的电线类型。
LuaCircuitNetwork = {}

--- 参数
--- signal :: SignalID：要读取的信号。
--- 返回值
--- 信号的当前值。
---@return integer count
---@param signal table 要读取的信号。
function LuaCircuitNetwork:get_signal(signal) end

---@class LuaCombinatorControlBehavior
---@field signals_last_tick table[] (只读) 该组合器在上一个 tick 发送的电路网络信号。
LuaCombinatorControlBehavior = {}

--- 获取该组合器行为在上一个 tick 发送的指定信号的值；若该信号不存在则为 nil。
--- 参数
--- signal :: SignalID: 要获取的信号
--- 返回值
--- 该值；若没有则为 nil。
---@return integer count
---@param signal table 要获取的信号。
function LuaCombinatorControlBehavior:get_signal_last_tick(signal) end

--- 自定义游戏控制台命令。这些命令不会在存档和读档之间持久保存；相反，脚本应在 LuaBootstrap::on_load 中重新注册它们的命令。
---@class LuaCommandProcessor
---@field commands table<string, table> (只读) 脚本通过 LuaCommandProcessor 注册的命令。
---@field game_commands table<string, table> (只读) 核心游戏的内置命令。
LuaCommandProcessor = {}

--- 添加一条命令。
--- 当命令被调用时，注册到该命令的函数会收到一个表。该表包含：
--- name :: string: 命令的名称。
--- tick :: uint: 命令被使用时的 tick。
--- player_index :: uint: 使用该命令的玩家。
--- parameter :: string (可选): 命令之后传入的参数，与命令之间用一个空格分隔。
--- 参数
--- name :: string: 命令的名称（区分大小写）。
--- help :: LocalisedString: 本地化的帮助信息。
--- function :: function: 当该命令被调用时将被执行的函数。
--- 注意： 如果给定的命令 name 已经注册，或已经作为游戏命令存在，则会产生错误。
---@param _function fun(...) 当此命令被调用时将执行的函数。
---@param help table 本地化的帮助消息。
---@param name string 命令的名称（区分大小写）。
function LuaCommandProcessor:add_command(_function, help, name) end

--- 移除一条已注册的命令。
--- 参数
--- 返回值
--- 若命令被移除则为 true；若命令不存在则为 false。
---@return boolean ok
---@param undefined any
function LuaCommandProcessor:remove_command(undefined) end

--- 常量组合器的控制行为。
---@class LuaConstantCombinatorControlBehavior
---@field enabled boolean 开启或关闭此常量组合器。
---@field entity LuaEntity (只读) 此控制行为所属的实体。
---@field help string 此对象支持的所有方法和属性。
---@field parameters table 常量组合器的参数。 注意： parameters 可以被设为 nil 以清除参数。 示例 behavior.parameters = {parameters = new_parameter
---@field signals_count integer (只读) 此常量组合器支持的信号数量。
---@field type defines.control_behavior.type (只读) 此控制行为的具体类型。
---@field valid boolean (只读) 此对象是否有效？
LuaConstantCombinatorControlBehavior = {}

--- 参数
--- wire :: defines.wire_type: 与此实体相连的网络的电线颜色。
--- circuit_connector :: defines.circuit_connector_id (可选): 要获取电路网络的连接器；对于拥有多个电路网络连接器的实体必须指定。
--- 返回值
--- 电路网络或 nil。
---@return LuaCircuitNetwork result
---@param circuit_connector defines.circuit_connector_id? 要获取其电路网络的连接器。
对于拥有多个电路网络连接器的实体，必须指定此项。
---@param wire defines.wire_type 连接到此实体的网络的导线颜色。
function LuaConstantCombinatorControlBehavior:get_circuit_network(circuit_connector, wire) end

--- 获取指定索引处的信号。如果该索引没有设置信号，返回的 Signal 将不包含信号。
--- 参数
--- index :: uint
---@return table result
---@param index integer
function LuaConstantCombinatorControlBehavior:get_signal(index) end

--- 设置指定索引处的信号。
--- 参数
--- index :: uint
--- signal :: Signal
---@param index integer
---@param signal table
function LuaConstantCombinatorControlBehavior:set_signal(index, signal) end

--- 容器实体的控制行为。
---@class LuaContainerControlBehavior
---@field entity LuaEntity (只读) 此控制行为所属的实体。
---@field help string 此对象支持的所有方法和属性。
---@field type defines.control_behavior.type (只读) 此控制行为的具体类型。
---@field valid boolean (只读) 此对象是否有效？
LuaContainerControlBehavior = {}

--- 参数
--- wire :: defines.wire_type: 与此实体相连的网络的电线颜色。
--- circuit_connector :: defines.circuit_connector_id (可选): 要获取电路网络的连接器；对于拥有多个电路网络连接器的实体必须指定。
--- 返回值
--- 电路网络或 nil。
---@return LuaCircuitNetwork result
---@param circuit_connector defines.circuit_connector_id? 要获取其电路网络的连接器。
对于拥有多个电路网络连接器的实体，必须指定此项。
---@param wire defines.wire_type 连接到此实体的网络的导线颜色。
function LuaContainerControlBehavior:get_circuit_network(circuit_connector, wire) end

--- 这是一个抽象基类，包含 LuaPlayer 与角色实体之间的通用功能（参见 LuaEntity）。当通过 LuaEntity 访问这些成员时，该 LuaEntity 必须指向一个角色实体。
---@class LuaControl
---@field auto_trash_filters table<string, integer> 自动垃圾桶过滤器。键是物品原型名称，值是槽位数值。 注意： 在 LuaPlayer 上调用时，必须与角色相关联（参见 LuaPlayer.character）。 示例 以下代码将自动垃圾桶槽位设置为在玩家库存中最多保留 20 个铁板和 42 个铜线： game.player.auto_trash_filters = {["iron-plate"] = 20, ["copper-cable"] = 42}
---@field build_distance integer (只读) 此角色的建造距离；如果不是角色或未连接到角色的玩家，则为最大 uint 值。
---@field character_additional_mining_categories string[] 注意： 在 LuaPlayer 上调用时，必须与角色相关联（参见 LuaPlayer.character）。
---@field character_build_distance_bonus integer 注意： 在 LuaPlayer 上调用时，必须与角色相关联（参见 LuaPlayer.character）。
---@field character_crafting_speed_modifier number 注意： 在 LuaPlayer 上调用时，必须与角色相关联（参见 LuaPlayer.character）。
---@field character_health_bonus number 注意： 在 LuaPlayer 上调用时，必须与角色相关联（参见 LuaPlayer.character）。
---@field character_inventory_slots_bonus integer 注意： 在 LuaPlayer 上调用时，必须与角色相关联（参见 LuaPlayer.character）。
---@field character_item_drop_distance_bonus integer 注意： 在 LuaPlayer 上调用时，必须与角色相关联（参见 LuaPlayer.character）。
---@field character_item_pickup_distance_bonus integer 注意： 在 LuaPlayer 上调用时，必须与角色相关联（参见 LuaPlayer.character）。
---@field character_logistic_slot_count_bonus integer 注意： 在 LuaPlayer 上调用时，必须与角色相关联（参见 LuaPlayer.character）。
---@field character_loot_pickup_distance_bonus integer 注意： 在 LuaPlayer 上调用时，必须与角色相关联（参见 LuaPlayer.character）。
---@field character_maximum_following_robot_count_bonus integer 注意： 在 LuaPlayer 上调用时，必须与角色相关联（参见 LuaPlayer.character）。
---@field character_mining_speed_modifier number 注意： 在 LuaPlayer 上调用时，必须与角色相关联（参见 LuaPlayer.character）。
---@field character_reach_distance_bonus integer 注意： 在 LuaPlayer 上调用时，必须与角色相关联（参见 LuaPlayer.character）。
---@field character_resource_reach_distance_bonus integer 注意： 在 LuaPlayer 上调用时，必须与角色相关联（参见 LuaPlayer.character）。
---@field character_running_speed number (只读) 获取此角色当前的移动速度，包括外骨骼、地面、减速贴片和射击等效果的影响。
---@field character_running_speed_modifier number 注意： 在 LuaPlayer 上调用时，必须与角色相关联（参见 LuaPlayer.character）。
---@field character_trash_slot_count_bonus integer 注意： 在 LuaPlayer 上调用时，必须与角色相关联（参见 LuaPlayer.character）。
---@field cheat_mode boolean 当为 true 时，手工制作免费且即时完成。
---@field crafting_queue table[] (只读) 获取当前制作队列中的条目。每个 CraftingQueueItem 是一个表： index :: uint: 制作队列索引 recipe :: string: 配方。 count :: uint: 正在制作的数量。
---@field crafting_queue_size integer (只读) 制作队列的大小。
---@field cursor_ghost table 玩家光标中的虚影原型。 注意： 读取时，它将是一个 LuaItemPrototype。 注意： 光标栏中的物品将优先于光标虚影。
---@field cursor_stack LuaItemStack (只读) 玩家的光标栏。
---@field driving boolean 如果玩家在载具中则为 true。写入此属性可使玩家进入或离开载具。
---@field drop_item_distance integer (只读) 此角色的物品丢弃距离；如果不是角色或未连接到角色的玩家，则为最大 uint 值。
---@field following_robots LuaEntity[] (只读) 当前跟随角色的战斗机器人。 注意： 在 LuaPlayer 上调用时，必须与角色相关联（参见 LuaPlayer.character）。
---@field force table 此实体的势力。读取时始终返回一个 LuaForce，但可以向此属性赋值 string 或 LuaForce 来更改势力。
---@field in_combat boolean (只读) 此角色实体是否处于战斗中。
---@field item_pickup_distance number (只读) 此角色的物品拾取距离；如果不是角色或未连接到角色的玩家，则为最大 double 值。
---@field loot_pickup_distance number (只读) 此角色的战利品拾取距离；如果不是角色或未连接到角色的玩家，则为最大 double 值。
---@field mining_state table 当前的采矿状态。 它是一个包含两个字段的表： mining :: boolean: 玩家是否正在采矿 position :: Position (可选): 玩家正在开采哪些地块；仅当玩家在开采地块（光标中持有地块）时使用。 注意： 当玩家不在开采地块时，玩家将开采当前选中的任何实体。参见 LuaControl.selected 和 LuaControl.update_selected_entity。
---@field opened LuaEntity | LuaItemStack | LuaEquipment | LuaEquipmentGrid | LuaPlayer | LuaGuiElement | defines.gui_type 玩家当前打开的界面目标；如果没有则为 nil。 注意： 写入支持所有类型。读取将返回实体、装备、元素或 nil。
---@field opened_gui_type defines.gui_type (只读) 返回 defines.gui_type 或 nil。
---@field picking_state boolean 当前的物品拾取状态。
---@field position table (只读) 实体的当前位置。
---@field reach_distance integer (只读) 此角色的触及距离；如果不是角色或未连接到角色的玩家，则为最大 uint 值。
---@field repair_state table 当前的维修状态。 它是一个包含两个字段的表： repairing :: boolean: 当前状态 position :: Position: 正在维修的位置
---@field resource_reach_distance number (只读) 此角色的资源触及距离；如果不是角色或未连接到角色的玩家，则为最大 double 值。
---@field riding_state table 此载具或此玩家正在乘坐的载具当前的驾驶状态。
---@field selected LuaEntity 当前选中的实体；如果没有则为 nil。赋予一个实体将在其可选中的情况下选中它，否则清除选中状态。
---@field shooting_state table 当前的射击状态。 它是一个包含两个字段的表： state :: defines.shooting: 当前状态 position :: Position: 正在射击的位置
---@field surface LuaSurface (只读) 此实体当前所在的地表。
---@field vehicle LuaEntity (只读) 玩家当前乘坐的载具；如果没有则为 nil。
---@field walking_state table 当前的行走状态。 它是一个包含两个字段的表： walking :: boolean: 如果为 false，玩家当前不在行走；否则玩家正在走向某处 direction :: defines.direction: 玩家行走的方向 示例 让玩家向北走。注意，像这样的一次性动作只会让玩家行走一个 tick： game.player.walking_state = {walking = true, direction = defines.direction.north}
LuaControl = {}

--- 开始制作给定数量的给定配方。
--- 参数
--- count :: uint: 要制作的数量。
--- recipe :: string 或 LuaRecipe: 要制作的配方。
--- silent :: boolean (可选): 如果为 false，当配方无法按请求次数制作时，将跳过打印失败信息。
--- 返回值
--- 实际开始制作的数量。
---@return integer count
---@param count integer? 要制造的数量。
recipe :: [string] 或 [LuaRecipe]：要制造的配方。
silent :: [boolean]（可选）：如果为 false，且配方无法按请求的次数制造，则跳过失败信息的打印。
function LuaControl:begin_crafting(count) end

--- 是否至少可以插入部分物品？
--- 参数
--- items :: ItemStackSpecification: 将要插入的物品。
--- 返回值
--- 如果给定物品中至少有一部分可以插入此物品栏，则为 true。
---@return boolean ok
---@param items table 将要插入的物品。
function LuaControl:can_insert(items) end

--- 给定的实体能否被打开或访问？
--- 参数
--- entity :: LuaEntity
---@return boolean ok
---@param entity LuaEntity
function LuaControl:can_reach_entity(entity) end

--- 取消制作指定制作队列索引处的指定数量。
--- 参数
--- options: :
--- index :: uint: 制作队列索引。
--- count :: uint: 要取消制作的数量。
---@param options integer 制造队列（crafting queue）索引。
count :: [uint]：要取消制造的数量。
function LuaControl:cancel_crafting(options) end

--- 移除由 set_gui_arrow 创建的箭头。
function LuaControl:clear_gui_arrow(...) end

--- 从此实体中移除所有物品。
function LuaControl:clear_items_inside(...) end

--- 取消选择任何已选中的实体。
function LuaControl:clear_selected_entity(...) end

--- 禁用闪光灯。
function LuaControl:disable_flashlight(...) end

--- 启用闪光灯。
function LuaControl:enable_flashlight(...) end

--- 获取给定配方可以制作的数量。
--- 参数
--- recipe :: string 或 LuaRecipe: 配方。
--- 返回值
--- 可以制作的数量。
---@return integer count
---@param recipe string | LuaRecipe 配方。
function LuaControl:get_craftable_count(recipe) end

--- 获取属于此实体的物品栏。可以是"主"物品栏，也可以是某种辅助物品栏，例如插件模块槽位或物流垃圾桶槽位。
--- 参数
--- inventory :: defines.inventory
--- 返回值
--- 如果此实体没有给定索引对应的物品栏，则返回 nil。
--- 注意： 给定的 defines.inventory 只对相应的 LuaObject 类型有意义。例如：get_inventory(defines.inventory.character_main) 仅在 'this' 是玩家角色时才有意义。你可能会得到一个返回值，但如果 'this' 的类型不是 defines.inventory 所对应的类型，那么几乎可以肯定返回的不是所请求的物品栏。
---@return LuaInventory result
---@param inventory defines.inventory
function LuaControl:get_inventory(inventory) end

--- 获取此实体中全部或部分物品的数量。
--- 参数
--- item :: string (可选): 要计数的物品的原型名称。如果未指定，则统计所有物品。
---@return integer count
---@param item string? 要计数的物品的原型名称。如果未指定，则统计所有物品。
function LuaControl:get_item_count(item) end

--- 如果这是角色或玩家，则获取此角色或玩家的主物品栏。
--- 返回值
--- 如果此实体不是角色或玩家，则返回 nil。
---@return LuaInventory result
function LuaControl:get_main_inventory(...) end

--- 此实体内部是否有任何物品？
---@return boolean ok
function LuaControl:has_items_inside(...) end

--- 向此实体插入物品。其工作方式与机械臂或 Shift 点击相同：会自动选择"最佳"物品栏。
--- 参数
--- items :: ItemStackSpecification: 要插入的物品。
--- 返回值
--- 实际插入的物品数量。
---@return integer count
---@param items table 要插入的物品。
function LuaControl:insert(items) end

--- 当为 true 时，控制适配器是一个 LuaPlayer 对象；对于实体（包括有玩家的角色）则为 false。
---@return boolean ok
function LuaControl:is_player(...) end

--- 像此玩家（或角色）亲自开采一样开采给定的实体。
--- 参数
--- entity :: LuaEntity: 要开采的实体
--- force :: boolean (可选): 即使物品无法放入玩家库存也强制开采该实体。
--- 返回值
--- 开采是否成功。
---@return boolean ok
---@param entity LuaEntity 要开采的实体。
---@param force boolean? 即使物品无法放入玩家（背包）中，也强制开采该实体。
function LuaControl:mine_entity(entity, force) end

--- 像此玩家（或角色）亲自开采一样开采给定的地块。
--- 参数
--- tile :: LuaTile: 要开采的地块。
--- 返回值
--- 开采是否成功。
---@return boolean ok
---@param tile LuaTile 要开采的地块（tile）。
function LuaControl:mine_tile(tile) end

--- 打开科技界面并选中给定的科技。
--- 参数
--- technology :: TechnologySpecification (可选): 打开界面后要选中的科技。
---@param technology table? 打开界面（GUI）后要选择的科技。
function LuaControl:open_technology_gui(technology) end

--- 从此实体中移除物品。
--- 参数
--- items :: ItemStackSpecification: 要移除的物品。
--- 返回值
--- 实际移除的物品数量。
---@return integer count
---@param items table 要移除的物品。
function LuaControl:remove_item(items) end

--- 创建指向此实体的箭头。这在教程中使用。示例请参见战役任务中的 control.lua。
--- 参数
--- 包含以下字段的表：
--- type :: string: 指向何处。此字段决定哪些其他字段是必需的。
--- 可以是 "nowhere"、"goal"、"entity_info"、"active_window"、"entity"、"position"、"crafting_queue" 或 "item_stack"。
--- 附加的 type 专属参数：
--- entity
--- entity :: LuaEntity
--- position
--- position :: Position
--- crafting_queue
--- crafting_queue index :: uint
--- item_stack
--- inventory_index :: defines.inventory
--- item_stack_index :: uint
--- source :: string: 可以是 "player" 或 "target"。
---@param type string 包含以下字段的表：
type :: [string]：指向的位置。此字段决定哪些其他字段是必需的。可以是 "nowhere"、"goal"、"entity_info"、"active_window"、"entity"、"position"、"crafting_queue" 或 "item_stack"。
附加的 type 专属参数：
entity
entity :: [LuaEntity]
position
position :: [Position]
crafting_queue
crafting_queue index :: [uint]
item_stack
inventory_index :: [defines.inventory]
item_stack_index :: [uint]
source :: [string]：可以是 "player" 或 "target"。
function LuaControl:set_gui_arrow(type) end

--- 将实体传送到给定位置，可能传送到另一个地表。
--- 参数
--- position :: Position: 传送到的位置。
--- surface :: SurfaceSpecification (可选): 要传送到的地表。如果未给出，将传送到实体当前所在的地表。
--- 返回值
--- 当实体成功传送时为 true。
--- 注意： 某些实体可能无法传送。例如，铁路信号灯不允许传送，对任何此类实体使用此方法时始终返回 false。
--- 注意： 你也可以传入 1 个或 2 个数字作为参数，它们将被用作相对传送坐标：
--- 'teleport(0, 1)' 将实体向正方向移动 1 格；
--- 'teleport(4)' 将实体向正 x 方向移动 4 格。
---@return boolean ok
---@param position table 要传送到的位置。
---@param surface table? 要传送到的地表。如果未指定，将传送到实体当前所在的地表。
function LuaControl:teleport(position, surface) end

--- 选中一个实体，就像将鼠标悬停在其上方一样。
--- 参数
--- position :: Position: 要选中的实体的位置
---@param position table 要选择的实体的位置。
function LuaControl:update_selected_entity(position) end

--- 实体的控制行为。机械臂具有物流网络和电路网络行为逻辑，灯具有电路逻辑，依此类推。这是一个抽象基类，具体控制行为继承自它。
---@class LuaControlBehavior
---@field entity LuaEntity (只读) 此控制行为所属的实体。
---@field type defines.control_behavior.type (只读) 此控制行为的具体类型。
LuaControlBehavior = {}

--- 参数
--- wire :: defines.wire_type: 与此实体相连的网络的电线颜色。
--- circuit_connector :: defines.circuit_connector_id (可选): 要获取电路网络的连接器；对于拥有多个电路网络连接器的实体必须指定。
--- 返回值
--- 电路网络或 nil。
---@return LuaCircuitNetwork result
---@param circuit_connector defines.circuit_connector_id? 要获取其电路网络的连接器。
对于拥有多个电路网络连接器的实体，必须指定此项。
---@param wire defines.wire_type 连接到此实体的网络的导线颜色。
function LuaControlBehavior:get_circuit_network(circuit_connector, wire) end

--- 显示在地图视图上的自定义标签。
---@class LuaCustomChartTag
---@field force LuaForce (只读) 此标签所属的势力。
---@field help string 此对象支持的所有方法和属性。
---@field icon table
---@field last_user LuaPlayer 最后编辑此标签的玩家。
---@field position table (只读) 此标签的位置。
---@field surface LuaSurface (只读) 此标签所属的地表。
---@field tag_number integer (只读) 此标签在此势力上的唯一 ID。
---@field text string
---@field valid boolean (只读) 此对象是否有效？
LuaCustomChartTag = {}

--- 销毁此标签。
function LuaCustomChartTag:destroy(...) end

--- 自定义输入的原型。
---@class LuaCustomInputPrototype
---@field alternative_key_sequence string (只读) 此自定义输入的默认备选按键序列；未定义时为 nil。
---@field consuming string (只读) 消费类型："none" 或 "game-only"。
---@field enabled boolean (只读) 此自定义输入是否已启用。已禁用的自定义输入仍然存在，但不会被游戏使用。
---@field help string 此对象支持的所有方法和属性。
---@field key_sequence string (只读) 此自定义输入的默认按键序列。
---@field linked_game_control string (只读) 关联的游戏控制名称或 nil。
---@field localised_description table (只读)
---@field localised_name table (只读)
---@field name string (只读) 此原型的名称。
---@field order string (只读) 此原型的排序字符串。
---@field valid boolean (只读) 此对象是否有效？
LuaCustomInputPrototype = {}

--- 惰性求值的表。
--- 出于性能考虑，我们有时会返回一种自定义的类表类型，而不是原生的 Lua 表。这种自定义类型会惰性地构造相应 C++ 对象所需的 Lua 包装器，从而在某些情况下避免不必要的构造。
---@class LuaCustomTable
---@field help string 此对象支持的所有方法和属性。
---@field _operator___ any 访问此自定义表的一个元素。
---@field _operator__ integer (只读) 此表中的元素数量。
---@field valid boolean (只读) 此对象是否有效？
LuaCustomTable = {}

--- 伤害的原型。
---@class LuaDamagePrototype
---@field help string 此对象支持的所有方法和属性。
---@field hidden boolean (只读) 此伤害类型是否在实体提示中隐藏。
---@field localised_description table (只读)
---@field localised_name table (只读)
---@field name string (只读) 此原型的名称。
---@field order string (只读) 此原型的排序字符串。
---@field valid boolean (只读) 此对象是否有效？
LuaDamagePrototype = {}

--- 决策组合器（decider combinator）的控制行为。
---@class LuaDeciderCombinatorControlBehavior
---@field entity LuaEntity (只读) 此控制行为所属的实体。
---@field help string 此对象支持的所有方法和属性。
---@field parameters table 决策组合器参数。 注意： parameters 可以为 nil，用于清除参数。
---@field signals_last_tick table[] (只读) 此组合器上一 tick 发送的电路网络信号。
---@field type defines.control_behavior.type (只读) 此控制行为的具体类型。
---@field valid boolean (只读) 此对象是否有效？
LuaDeciderCombinatorControlBehavior = {}

--- 参数
--- wire :: defines.wire_type：连接到该实体的网络的电线颜色。
--- circuit_connector :: defines.circuit_connector_id（可选）：要获取电路网络的连接器；对于拥有多个电路网络连接器的实体必须指定。
--- 返回值
--- 电路网络或 nil。
---@return LuaCircuitNetwork result
---@param circuit_connector defines.circuit_connector_id? 要获取其电路网络的连接器。
对于拥有多个电路网络连接器的实体，必须指定此项。
---@param wire defines.wire_type 连接到此实体的网络的导线颜色。
function LuaDeciderCombinatorControlBehavior:get_circuit_network(circuit_connector, wire) end

--- 获取此组合器行为上一 tick 发送的特定信号的值；如果该信号不存在则为 nil。
--- 参数
--- signal :: SignalID：要获取的信号
--- 返回值
--- 该值；若无则为 nil。
---@return integer count
---@param signal table 要获取的信号。
function LuaDeciderCombinatorControlBehavior:get_signal_last_tick(signal) end

--- 优化装饰物（decorative）的原型。
---@class LuaDecorativePrototype
---@field autoplace_specification table (只读) 此装饰物原型的自动放置（autoplace）规范；如果没有则为 nil。
---@field collision_box table (只读) 用于碰撞检测的包围盒。
---@field help string 此对象支持的所有方法和属性。
---@field localised_description table (只读)
---@field localised_name table (只读)
---@field name string (只读) 此原型的名称。
---@field order string (只读) 此原型的排序字符串（order）。
---@field valid boolean (只读) 此对象是否有效？
LuaDecorativePrototype = {}

--- 电力能量源（electric energy source）的原型。
---@class LuaElectricEnergySourcePrototype
---@field buffer_capacity number (只读)
---@field drain number (只读)
---@field emissions number (只读)
---@field help string 此对象支持的所有方法和属性。
---@field input_flow_limit number (只读)
---@field output_flow_limit number (只读)
---@field render_no_network_icon boolean (只读)
---@field render_no_power_icon boolean (只读)
---@field usage_priority string (只读)
---@field valid boolean (只读) 此对象是否有效？
LuaElectricEnergySourcePrototype = {}

--- 通过 Lua API 与实体交互的主要接口。地图上除地块（tile）之外的一切都是实体。
---@class LuaEntity
---@field active boolean 停用实体将停止其所有操作（汽车将停止移动、机械臂将停止工作、鱼将停止游动等）。 注意： 天然不活动的实体无法被设置为活动（将其设置为活动不会有任何效果）。 注意： 虚影（ghost）、简单烟雾（simple smoke）和尸体目前无法被修改。 注意： 甚至可以设置角色为不活动，这样他就无法移动或执行大多数任务。
---@field ai_settings LuaAISettings (只读) 此单位（unit）的 AI 设置。 仅当这是单位（Unit）时可用。
---@field alert_parameters table 仅当这是可编程扬声器（ProgrammableSpeaker）时可用。
---@field allow_dispatching_robots boolean 是否允许此角色的个人机器人港口（roboport）派遣机器人。 仅当这是角色（Character）时可用。
---@field amount integer 包含的资源单位数量。 仅当这是资源实体（ResourceEntity）时可用。
---@field armed boolean (只读) 此地面雷是否已布设（armed）。 仅当这是地面雷（LandMine）时可用。
---@field associated_player LuaPlayer 与此角色关联的玩家；如果没有则为 nil。当玩家在多人游戏中下线时，所有关联的角色也会随之注销。 注意： 与玩家关联的角色并不由任何玩家直接控制。 注意： 设置为 nil 以清除。当在角色上设置控制器时，玩家将自动解除关联。 仅当这是角色（Character）时可用。
---@field auto_launch boolean 此火箭发射井是否在装入货物后自动发射火箭。 仅当这是火箭发射井（RocketSilo）时可用。
---@field auto_trash_filters table<string, integer> 自动垃圾（auto-trash）过滤器。键是物品原型名称，值是栏位数量。 注意： 当在 LuaPlayer 上调用时，它必须与一个角色关联（参见 LuaPlayer::character）。 示例 这将设置自动垃圾栏位，使玩家物品栏中最多保留 20 个铁板和 42 个铜线： game.player.auto_trash_filters = {["iron-plate"] = 20, ["copper-cable"] = 42}
---@field backer_name string 分配给实验室或火车站/停靠站（stop）的（Factorio）支持者（backer）名称。 注意： 仅可用于支持支持者名称的实体。当实体不支持支持者名称时返回 nil。
---@field belt_to_ground_type string (只读) "input" 或 "output"，取决于该地下传送带是向下（输入）还是向上（输出）。 仅当这是地下传送带（TransportBeltToGround）时可用。
---@field bonus_mining_progress number 此采矿钻机的奖励开采进度；如果不是采矿钻机则为 nil。读取时返回 [0, mining_target.prototype.mineable_properties.mining_time] 范围内的数字。
---@field bonus_progress number 当前生产力加成进度，为 [0, 1] 范围内的数字。 仅当这是制造机（CraftingMachine）时可用。
---@field bounding_box table (只读)
---@field build_distance integer (只读) 此角色的建造距离；当不是角色或未连接到角色的玩家时返回最大 uint。
---@field burner LuaBurner (只读) 此实体的燃烧能量源；如果没有则为 nil。
---@field chain_signal_state defines.chain_signal_state (只读) 此链式信号灯（chain signal）的状态。 仅当这是铁路链式信号灯（RailChainSignal）时可用。
---@field character_additional_mining_categories string[] 注意： 当在 LuaPlayer 上调用时，它必须与一个角色关联（参见 LuaPlayer::character）。
---@field character_build_distance_bonus integer 注意： 当在 LuaPlayer 上调用时，它必须与一个角色关联（参见 LuaPlayer::character）。
---@field character_corpse_death_cause table 此角色尸体死亡的原因（如果有）。 仅当这是角色尸体（CharacterCorpse）时可用。
---@field character_corpse_player_index integer 与此角色尸体关联的玩家索引。 注意： 该索引不保证有效，因此应始终先检查具有该索引的玩家是否确实存在。 仅当这是角色尸体（CharacterCorpse）时可用。
---@field character_corpse_tick_of_death integer 此角色尸体死亡的 tick。 仅当这是角色尸体（CharacterCorpse）时可用。
---@field character_crafting_speed_modifier number 注意： 当在 LuaPlayer 上调用时，它必须与一个角色关联（参见 LuaPlayer::character）。
---@field character_health_bonus number 注意： 当在 LuaPlayer 上调用时，它必须与一个角色关联（参见 LuaPlayer::character）。
---@field character_inventory_slots_bonus integer 注意： 当在 LuaPlayer 上调用时，它必须与一个角色关联（参见 LuaPlayer::character）。
---@field character_item_drop_distance_bonus integer 注意： 当在 LuaPlayer 上调用时，它必须与一个角色关联（参见 LuaPlayer::character）。
---@field character_item_pickup_distance_bonus integer 注意： 当在 LuaPlayer 上调用时，它必须与一个角色关联（参见 LuaPlayer::character）。
---@field character_logistic_slot_count_bonus integer 注意： 当在 LuaPlayer 上调用时，它必须与一个角色关联（参见 LuaPlayer::character）。
---@field character_loot_pickup_distance_bonus integer 注意： 当在 LuaPlayer 上调用时，它必须与一个角色关联（参见 LuaPlayer::character）。
---@field character_maximum_following_robot_count_bonus integer 注意： 当在 LuaPlayer 上调用时，它必须与一个角色关联（参见 LuaPlayer::character）。
---@field character_mining_speed_modifier number 注意： 当在 LuaPlayer 上调用时，它必须与一个角色关联（参见 LuaPlayer::character）。
---@field character_reach_distance_bonus integer 注意： 当在 LuaPlayer 上调用时，它必须与一个角色关联（参见 LuaPlayer::character）。
---@field character_resource_reach_distance_bonus integer 注意： 当在 LuaPlayer 上调用时，它必须与一个角色关联（参见 LuaPlayer::character）。
---@field character_running_speed number (只读) 获取此角色的当前移动速度，包括外骨骼、地块、粘液（sticker）和射击带来的效果。
---@field character_running_speed_modifier number 注意： 当在 LuaPlayer 上调用时，它必须与一个角色关联（参见 LuaPlayer::character）。
---@field character_trash_slot_count_bonus integer 注意： 当在 LuaPlayer 上调用时，它必须与一个角色关联（参见 LuaPlayer::character）。
---@field cheat_mode boolean 当为 true 时，手工制作免费且即时完成。
---@field circuit_connected_entities table (只读) 通过电路网络连接到该实体的实体。它是一个表： red :: LuaEntity 数组：通过红线连接的实体。 green :: LuaEntity 数组：通过绿线连接的实体。
---@field circuit_connection_definitions table[] (只读) 通过电路网络连接到该实体的实体的连接定义。每个 CircuitConnectionDefinition 是一个表： wire :: defines.wire_type：电线颜色，可以是 defines.wire_type.red 或 defines.wire_type.green。 target_entity :: LuaEntity source_circuit_id :: uint target_circuit_id :: uint
---@field cliff_orientation string (只读) 此悬崖（cliff）的朝向。
---@field color table 角色、机车车辆（rolling stock）、火车站、飘浮文字或带所有者的简单实体（simple-entity-with-owner）的颜色。如果该实体不使用自定义颜色则返回 nil。
---@field connected_rail LuaEntity (只读) 此火车站连接到的铁路实体；如果没有则为 nil。 仅当这是火车站（TrainStop）时可用。
---@field consumption_modifier number 乘以能量消耗。 仅当这是汽车（Car）时可用。
---@field crafting_progress number 当前制作进度，为 [0, 1] 范围内的数字。 仅当这是制造机（CraftingMachine）时可用。
---@field crafting_queue table[] (只读) 获取当前制作队列中的物品。每个 CraftingQueueItem 是一个表： index :: uint：制作队列索引 recipe :: string：配方。 count :: uint：正在制作的数量。
---@field crafting_queue_size integer (只读) 制作队列的大小。
---@field crafting_speed number (只读) 当前制作速度，包括来自插件模块（module）和信标（beacon）的速度加成。 仅当这是制造机（CraftingMachine）时可用。
---@field cursor_ghost table 玩家光标中的虚影原型。 注意： 读取时它将是一个 LuaItemPrototype。 注意： 光标堆叠中的物品优先于光标虚影。
---@field cursor_stack LuaItemStack (只读) 玩家的光标堆叠。
---@field damage_dealt number 此炮塔、火炮炮塔（artillery turret）或火炮车厢（artillery wagon）造成的伤害。 仅当这是炮塔（Turret）时可用。
---@field destructible boolean 当实体不可摧毁时，它无法受到伤害。 注意： 不可摧毁的实体仍然可以被开采。 注意： 天然不可摧毁的实体（没有生命值，如烟雾、资源等）无法被设置为可摧毁。
---@field direction defines.direction 该实体当前朝向的方向。
---@field driving boolean 如果玩家在载具中则为 true。写入此属性会将玩家放入或移出载具。
---@field drop_item_distance integer (只读) 此角色的物品丢弃距离；当不是角色或未连接到角色的玩家时返回最大 uint。
---@field drop_position table 实体放置其物品的位置。 注意： 仅对会把物品放到某处的实体有意义，例如采矿钻机或机械臂（inserter）。采矿钻机无法更改其掉落位置；机械臂必须在其原型上将 allow_custom_vectors 设置为 true 才能允许更改掉落位置。
---@field drop_target LuaEntity 该实体将物品放入的目标实体；如果没有这样的实体则为 nil。 注意： 仅对会把物品放到某处的实体有意义，例如采矿钻机或机械臂。
---@field effectivity_modifier number 乘以载具每单位能量可产生的加速度。默认为 1。 仅当这是汽车（Car）时可用。
---@field effects table (只读) 正在应用于该实体的效果；如果没有则为 nil。对于信标，这是信标正在广播的效果。
---@field electric_buffer_size number 电力能量源的缓冲大小；如果实体没有电力能量源则为 nil。 注意： 写入访问仅限于 ElectricEnergyInterface 类型。
---@field electric_drain number (只读) 电力能量源的电力消耗（drain）；如果实体没有电力能量源则为 nil。
---@field electric_emissions number (只读) 电力能量源的排放量；如果实体没有电力能量源则为 nil。
---@field electric_input_flow_limit number (只读) 电力能量源的输入流量限制；如果实体没有电力能量源则为 nil。
---@field electric_network_id integer (只读) 返回该实体连接到的电力网络的 id；如果没有则为 nil。
---@field electric_network_statistics LuaFlowStatistics (只读) 此电线杆的电力网络统计。 仅当这是电线杆（ElectricPole）时可用。
---@field electric_output_flow_limit number (只读) 电力能量源的输出流量限制；如果实体没有电力能量源则为 nil。
---@field enable_logistics_while_moving boolean 此载具移动时是否启用装备栏（equipment grid）物流。 仅当这是载具（Vehicle）时可用。
---@field energy number 实体中存储的能量（熔炉中的热量、电气设备中存储的能量等）。对于没有能量存储概念的实体始终为 0。 示例 game.player.print("Machine energy: " .. game.player.selected.energy .. "J") game.player.selected.energy = 3000
---@field filter_slot_count integer (只读) 此机械臂或装卸机（loader）的过滤器栏位数量。如果不是机械臂或装卸机则为 0。
---@field fluidbox LuaFluidBox 此实体的流体箱（fluidbox）。
---@field following_robots LuaEntity[] (只读) 当前跟随角色的战斗机器人。 注意： 当在 LuaPlayer 上调用时，它必须与一个角色关联（参见 LuaPlayer::character）。
---@field force table 该实体的势力。读取时始终返回 LuaForce，但也可以为此属性分配 string 或 LuaForce 来更改势力。
---@field friction_modifier number 乘以汽车的摩擦力。 示例 这将使汽车行驶得快得多： game.player.vehicle.friction_modifier = 0.5 仅当这是汽车（Car）时可用。
---@field ghost_localised_description table (只读) 仅当这是虚影（Ghost）时可用。
---@field ghost_localised_name table (只读) 此虚影中包含的实体或地块的本地化名称。 仅当这是虚影（Ghost）时可用。
---@field ghost_name string (只读) 此虚影中包含的实体或地块的名称。 仅当这是虚影（Ghost）时可用。
---@field ghost_prototype LuaEntityPrototype | LuaTilePrototype (只读) 此虚影中包含的实体或地块的原型。 仅当这是虚影（Ghost）时可用。
---@field ghost_type string (只读) 此虚影中包含的实体或地块的原型类型。 仅当这是虚影（Ghost）时可用。
---@field graphics_variation integer 此实体的图形变体；如果该实体不使用图形变体则为 nil。
---@field grid LuaEquipmentGrid (只读) 装备栏（equipment grid）；如果该实体没有装备栏则为 nil。
---@field health number 实体的生命值。将生命值设置为小于 0 会将其设置为 0，生命值为 0 的实体无法被攻击。将生命值设置为高于最大生命值会将其设置为最大生命值。 注意： 如果用于不支持生命值的实体，此字段将为 nil。
---@field held_stack LuaItemStack (只读) 机械臂手中当前持有的物品堆叠。 仅当这是机械臂（Inserter）时可用。
---@field held_stack_position table (只读) 机械臂"手"的当前位置。 仅当这是机械臂（Inserter）时可用。
---@field help string 此对象支持的所有方法和属性。
---@field highlight_box_blink_interval integer 此高亮框（highlight box）实体的闪烁间隔。0 表示不闪烁。 仅当这是高亮框（HighlightBox）时可用。
---@field highlight_box_type string 此高亮框实体的高亮框类型。 仅当这是高亮框（HighlightBox）时可用。
---@field in_combat boolean (只读) 此角色实体是否处于战斗中。
---@field infinity_container_filters table[] 此无限容器的过滤器。 仅当这是无限容器（InfinityContainer）时可用。
---@field initial_amount integer 包含的初始资源单位数量。 注意： 如果这不是无限资源，读取将返回 nil，写入将报错。 仅当这是资源实体（ResourceEntity）时可用。
---@field inserter_filter_mode string 此过滤机械臂的过滤模式："whitelist"、"blacklist"；如果该机械臂不使用过滤器则为 nil。 仅当这是机械臂（Inserter）时可用。
---@field inserter_stack_size_override integer 设置此机械臂的堆叠大小上限。如果堆叠大小大于势力堆叠大小上限，则该值被忽略。 注意： 设置为 0 以重置。
---@field item_pickup_distance number (只读) 此角色的物品拾取距离；当不是角色或未连接到角色的玩家时返回最大 double。
---@field item_requests table<string, integer> 此虚影在被复活时将请求的物品，或此物品请求代理（item request proxy）正在请求的物品。结果是字典，将每个物品原型名称映射到所需数量。
---@field kills integer 此炮塔、火炮炮塔或火炮车厢杀死的单位数量。 仅当这是炮塔（Turret）时可用。
---@field last_user LuaPlayer 建造此实体的玩家。 仅当这是有所有者的实体（EntityWithOwner）时可用。
---@field loader_type string "input" 或 "output"，取决于该装卸机是放入还是取出容器。 仅当这是装卸机（Loader）时可用。
---@field localised_description table (只读)
---@field localised_name table (只读) 实体的本地化名称。
---@field logistic_cell LuaLogisticCell (只读) 该实体所属的物流单元（logistic cell）。如果该实体不属于任何物流单元则为 nil。
---@field logistic_network LuaLogisticNetwork (只读) 该实体所属的物流网络。
---@field loot_pickup_distance number (只读) 此角色的战利品拾取距离；当不是角色或未连接到角色的玩家时返回最大 double。
---@field minable boolean 注意： 不可开采的实体仍然可以被摧毁。 注意： 天然不可开采的实体（如烟雾、角色、敌方单位等）无法被设置为可开采。
---@field mining_progress number 此采矿钻机的开采进度；如果不是采矿钻机则为 nil。是 [0, mining_target.prototype.mineable_properties.mining_time] 范围内的数字。
---@field mining_state table 当前开采状态。它是一个包含两个字段的表： mining :: boolean：玩家是否在开采 position :: Position（可选）：玩家正在开采哪些地块；仅当玩家正在开采地块（光标中持有地块）时使用。 注意： 当玩家未在开采地块时，玩家将开采当前选中的任何实体。参见 LuaControl::selected 和 LuaControl::update_selected_entity。
---@field mining_target LuaEntity (只读) 开采目标；如果没有则为 nil。 仅当这是采矿钻机（MiningDrill）时可用。
---@field moving LuaEntity (只读) 如果此单位正在移动则返回 true。 仅当这是单位（Unit）时可用。
---@field name string (只读) 实体原型的名称。例如 "inserter" 或 "filter-inserter"。
---@field neighbour_bonus number (只读) 此反应堆（reactor）当前的总相邻加成。 仅当这是反应堆（Reactor）时可用。
---@field neighbours table<string, LuaEntity | LuaEntity[][][]> (只读) 当在电线杆上调用时，这是所有连接的字典，以字符串 "copper"、"red" 和 "green" 作为索引。 当在可连接管道实体上调用时，这是实体数组的数组，表示给定流体箱连接到的所有实体。 当在地下传送带上调用时，这是地下传送带连接的另一端；如果没有则为 nil。 当在可连接墙壁实体或反应堆上调用时，这是所有连接的字典，以连接方向 "north"、"south"、"east" 和 "west" 作为索引。
---@field opened LuaEntity | LuaItemStack | LuaEquipment | LuaEquipmentGrid | LuaPlayer | LuaGuiElement | defines.gui_type 玩家当前打开的 GUI 目标；如果没有则为 nil。 注意： 写入支持任何类型。读取将返回实体、装备、元素或 nil。
---@field opened_gui_type defines.gui_type (只读) 返回 defines.gui_type 或 nil。
---@field operable boolean 当实体不可操作时，玩家无法打开其实体 GUI，也无法快速插入/输入物品。
---@field orientation number 平滑朝向（orientation）。
---@field parameters table 仅当这是可编程扬声器（ProgrammableSpeaker）时可用。
---@field picking_state boolean 当前物品拾取状态。
---@field pickup_position table 机械臂将从中拾取物品的位置。 注意： 机械臂必须在其原型上将 allow_custom_vectors 设置为 true 才能允许更改拾取位置。 仅当这是机械臂（Inserter）时可用。
---@field pickup_target LuaEntity 机械臂将尝试从中拾取的实体。例如，这可以是传送带或储物箱。 仅当这是机械臂（Inserter）时可用。
---@field player LuaPlayer (只读) 连接到该角色的玩家；如果没有则为 nil。 仅当这是角色（Character）时可用。
---@field position table (只读) 实体的当前位置。
---@field power_production number 特定于 ElectricEnergyInterface 实体类型的电力生产。 仅当这是电力能量接口（ElectricEnergyInterface）时可用。
---@field power_switch_state boolean 此电力开关（power switch）的状态。
---@field power_usage number 特定于 ElectricEnergyInterface 实体类型的电力消耗。 仅当这是电力能量接口（ElectricEnergyInterface）时可用。
---@field previous_recipe LuaRecipe (只读) 此熔炉之前使用的配方；如果熔炉没有之前的配方则为 nil。 仅当这是熔炉（Furnace）时可用。
---@field products_finished integer 仅当这是制造机（CraftingMachine）时可用。
---@field prototype LuaEntityPrototype (只读) 此实体的实体原型。
---@field proxy_target LuaEntity (只读) 此物品请求代理的目标实体；如果没有则为 nil。
---@field pump_rail_target LuaEntity (只读) 此泵（pump）的铁轨目标；如果没有则为 nil。 仅当这是泵（Pump）时可用。
---@field reach_distance integer (只读) 此角色的触及距离；当不是角色或未连接到角色的玩家时返回最大 uint。
---@field recipe_locked boolean 锁定时，此组装机中的配方无法被玩家更改。 仅当这是组装机（AssemblingMachine）时可用。
---@field relative_turret_orientation number 载具炮塔的相对朝向；如果该实体不是载具或没有载具炮塔则为 nil。 注意： 如果载具没有炮塔，写入不做任何事。 仅当这是载具（Vehicle）时可用。
---@field remove_unfiltered_items boolean 是否应从容器中移除不包含在此无限容器过滤器中的物品。 仅当这是无限容器（InfinityContainer）时可用。
---@field render_player LuaPlayer 此带所有者的简单实体、带势力的简单实体、飘浮文字或高亮框对其可见的玩家；如果没有则为 nil。设置为 nil 以清除。
---@field render_to_forces table[] 此带所有者的简单实体、带势力的简单实体或飘浮文字对其可见的势力；如果没有则为 nil。设置为 nil 以清除。 注意： 读取时始终给出 LuaForce 数组。
---@field repair_state table 当前修复状态。它是一个包含两个字段的表： repairing :: boolean：当前状态 position :: Position：正在修复的位置。
---@field request_slot_count integer (只读) 该实体拥有的请求栏位数量。
---@field resource_reach_distance number (只读) 此角色的资源触及距离；当不是角色或未连接到角色的玩家时返回最大 double。
---@field riding_state table 此汽车的当前乘坐状态，或此玩家正在乘坐的载具的乘坐状态。
---@field rocket_parts integer 发射井中的火箭部件数量。 仅当这是火箭发射井（RocketSilo）时可用。
---@field rotatable boolean 当实体不可旋转（机械臂、传送带等）时，玩家无法使用 R 键旋转它。 注意： 天然不可旋转的实体（如箱子或熔炉）无法被设置为可旋转。
---@field secondary_bounding_box table (只读) 此实体的次要包围盒；如果没有则为 nil。
---@field secondary_selection_box table (只读) 此实体的次要选择框；如果没有则为 nil。
---@field selected LuaEntity 当前选中的实体；如果没有则为 nil。分配一个实体将选择它（如果可选中），否则清除选择。
---@field selected_gun_index integer 此角色当前选中的武器栏位索引。 仅当这是角色（Character）时可用。
---@field selection_box table (只读)
---@field shooting_state table 当前射击状态。它是一个包含两个字段的表： state :: defines.shooting：当前状态 position :: Position：正在射击的位置。
---@field shooting_target LuaEntity 此炮塔的射击目标；如果没有则为 nil。
---@field signal_state defines.signal_state (只读) 此铁路信号灯的状态。 仅当这是铁路信号灯（RailSignal）时可用。
---@field spawner LuaEntity (只读) 与此单位实体关联的巢穴；如果该单位没有关联的巢穴则为 nil。
---@field speed number 汽车或机车车辆的当前速度，或单位的当前最大速度。只有单位和汽车的速度可写。
---@field splitter_filter LuaItemPrototype 此分流器（splitter）的过滤器；如果没有设置过滤器则为 nil。 仅当这是分流器（Splitter）时可用。
---@field splitter_input_priority string 此分流器的输入优先级："left"、"none" 或 "right"。 仅当这是分流器（Splitter）时可用。
---@field splitter_output_priority string 此分流器的输出优先级："left"、"none" 或 "right"。 仅当这是分流器（Splitter）时可用。
---@field stack LuaItemStack (只读) 仅当这是物品实体（ItemEntity）时可用。
---@field status defines.entity_status (只读) 该实体的状态；如果没有状态则为 nil。
---@field sticked_to LuaEntity (只读) 此粘液（sticker）粘附到的实体。
---@field stickers LuaEntity[] (只读) 附着在该实体上的粘液实体。
---@field supports_direction boolean (只读) 实体是否具有方向。当它对此实体为 false 时，询问方向将始终返回北方向。
---@field surface LuaSurface (只读) 该实体当前所在的地表。
---@field temperature number 如果该实体使用热能能量源，则为该实体热能能量源的温度；否则为 nil。
---@field text table 此飘浮文字实体的文本。 仅当这是飘浮文字（FlyingText）时可用。
---@field tick_of_last_attack integer (只读) 此角色实体上次被攻击的 tick。 仅当这是角色（Character）时可用。
---@field tick_of_last_damage integer (只读) 此角色实体上次受到伤害的 tick。 仅当这是角色（Character）时可用。
---@field time_to_live integer 虚影、战斗机器人或高亮框在被摧毁前剩余的 tick 数。 对于虚影，设置为 uint32 最大值（4,294,967,295）以永不过期。 对于虚影，不能设置得高于实体势力的 LuaForce::ghost_time_to_live。
---@field timeout integer 此地面雷（landmine）上剩余的引信时间（tick 数）。 仅当这是地面雷（LandMine）时可用。
---@field to_be_looted boolean 玩家走过时该实体是否会被自动拾取。 仅当这是物品实体（ItemEntity）时可用。
---@field train LuaTrain (只读) 此机车车辆所属的火车；如果不是机车车辆则为 nil。 仅当这是机车车辆（RollingStock）时可用。
---@field trains_in_block integer (只读) 此铁路实体的铁路区块（rail block）中的火车数量。 仅当这是铁轨（Rail）时可用。
---@field tree_color_index integer 树颜色索引。
---@field tree_color_index_max integer (只读) 树颜色的最大索引。
---@field tree_stage_index integer 树生长阶段索引。
---@field tree_stage_index_max integer (只读) 树生长阶段的最大索引。
---@field type string (只读) 该实体的实体原型类型。
---@field unit_group LuaUnitGroup (只读) 该单位所属的单位组；如果没有则为 nil。 仅当这是单位（Unit）时可用。
---@field unit_number integer (只读) 单位编号；如果实体没有则为 nil。对于拥有单位编号的每个实体，这在整局游戏的存续期内是全局唯一的。
---@field units LuaEntity[] (只读) 与此巢穴实体关联的单位。
---@field valid boolean (只读) 此对象是否有效？
---@field vehicle LuaEntity (只读) 玩家当前乘坐的载具；如果没有则为 nil。
---@field walking_state table 当前行走状态。它是一个包含两个字段的表： walking :: boolean：如果为 false，玩家当前没有行走；否则玩家正在前往某处。 direction :: defines.direction：玩家行走的方向。 示例 让玩家向北走。请注意，像这样的一次性动作只会让玩家走一个 tick： game.player.walking_state = {walking = true, direction = defines.direction.north}
LuaEntity = {}

--- 在市场（market）上提供一件物品。
--- 参数
--- offer :: Offer
--- 示例
--- 添加市场报价：1 个铜矿换 10 个铁矿石：
--- market.add_market_item{price={{"iron-ore", 10}}, offer={type="give-item", item="copper-ore"}}
--- 示例
--- 添加市场报价：1 个铜矿换 5 个铁矿石和 5 个石头：
--- market.add_market_item{price={{"iron-ore", 5}, {"stone", 5}}, offer={type="give-item", item="copper-ore"}}
--- 仅当这是市场（Market）时可用。
---@param offer table
function LuaEntity:add_market_item(offer) end

--- 开始制作给定数量的给定配方。
--- 参数
--- count :: uint：要制作的数量。
--- recipe :: string 或 LuaRecipe：要制作的配方。
--- silent :: boolean（可选）：如果为 false 且配方无法按要求的次数制作，则跳过打印失败信息。
--- 返回值
--- 实际开始制作的数量。
---@return integer count
---@param count integer? 要制造的数量。
recipe :: [string] 或 [LuaRecipe]：要制造的配方。
silent :: [boolean]（可选）：如果为 false，且配方无法按请求的次数制造，则跳过失败信息的打印。
function LuaEntity:begin_crafting(count) end

--- 检查该实体是否可以被摧毁。
--- 返回值
--- 该实体是否可以被摧毁。
---@return boolean ok
function LuaEntity:can_be_destroyed(...) end

--- 是否至少可以插入部分物品？
--- 参数
--- items :: ItemStackSpecification：将要插入的物品。
--- 返回值
--- 如果给定物品中至少有一部分可以插入到此物品栏中则返回 true。
---@return boolean ok
---@param items table 将要插入的物品。
function LuaEntity:can_insert(items) end

--- 给定的实体能否被打开或访问？
--- 参数
--- entity :: LuaEntity
---@return boolean ok
---@param entity LuaEntity
function LuaEntity:can_reach_entity(entity) end

--- 取消制作给定制作队列索引的给定数量。
--- 参数
--- options: :
--- index :: uint：制作队列索引。
--- count :: uint：要取消制作的数量。
---@param options integer 制造队列（crafting queue）索引。
count :: [uint]：要取消制造的数量。
function LuaEntity:cancel_crafting(options) end

--- 如果已安排拆除则取消拆除，否则不做任何事。
--- 参数
--- force :: ForceSpecification：下达拆除命令的势力（force）。
--- player :: PlayerSpecification（可选）：如果有的话，要设置为 last_user 的玩家。
---@param force table 下达拆除（deconstruction）命令的势力。
---@param player table? 要将其设置为 last_user 的玩家（如果有）。
function LuaEntity:cancel_deconstruction(force, player) end

--- 如果已安排升级则取消升级，否则不做任何事。
--- 参数
--- force :: ForceSpecification：下达升级命令的势力。
--- player :: PlayerSpecification（可选）：如果有的话，要设置为 last_user 的玩家。
--- 返回值
--- 取消是否成功。
---@return boolean ok
---@param force table 下达升级（upgrade）命令的势力。
---@param player table? 要将其设置为 last_user 的玩家（如果有）。
function LuaEntity:cancel_upgrade(force, player) end

--- 从该实体移除所有流体。
function LuaEntity:clear_fluid_inside(...) end

--- 移除由 set_gui_arrow 创建的箭头。
function LuaEntity:clear_gui_arrow(...) end

--- 从该实体移除所有物品。
function LuaEntity:clear_items_inside(...) end

--- 从市场移除所有报价。
--- 仅当这是市场（Market）时可用。
function LuaEntity:clear_market_items(...) end

--- 清除一个物流请求栏位。
--- 参数
--- slot :: uint：栏位索引。
--- 注意： 仅可用于拥有请求栏位的实体。
---@param slot integer 栏位（slot）索引。
function LuaEntity:clear_request_slot(slot) end

--- 取消选择任何已选中的实体。
function LuaEntity:clear_selected_entity(...) end

--- 克隆该实体。
--- 参数
--- 包含以下字段的表：
--- position :: LuaEntity：目标位置
--- surface :: LuaSurface（可选）：目标地表
--- force :: ForceSpecification（可选）
--- 返回值
--- 克隆出的实体；如果该实体无法被克隆或无法克隆到给定位置则为 nil。
--- 注意： 会触发 defines.events.on_entity_cloned 事件。
---@return LuaEntity entity
---@param position LuaEntity? 包含以下字段的表：
position :: [LuaEntity]：目标位置
surface :: [LuaSurface]（可选）：目标地表
force :: [ForceSpecification]（可选）
function LuaEntity:clone(position) end

--- 用导线或电缆连接两个设备。
--- 参数
--- target :: LuaEntity 或 table。
--- 要连接两个电线杆，target 必须是 LuaEntity，指定另一个电线杆。这将用铜缆连接它们。
--- 要用导线连接两个设备，此参数是一个表：
--- wire :: defines.wire_type：电线颜色，可以是 defines.wire_type.red 或 defines.wire_type.green。
--- target_entity :: LuaEntity：要连接导线的实体。
--- source_circuit_id :: uint（可选）：如果源实体有多个电路连接器则必须指定。
--- target_circuit_id :: uint（可选）：如果目标实体有多个电路连接器则必须指定。
--- 返回值
--- 连接是否建立。
---@return boolean ok
---@param target LuaEntity | table? wire :: [defines.wire_type]：导线颜色，可以是 [defines.wire_type.red] 或 [defines.wire_type.green]。
target_entity :: [LuaEntity]：要连接导线的实体
source_circuit_id :: [uint]（可选）：如果源实体有多个电路（circuit）连接器，则此项为必需。
target_circuit_id :: [uint]（可选）：如果目标实体有多个电路（circuit）连接器，则此项为必需。
function LuaEntity:connect_neighbour(target) end

--- 沿给定方向连接机车车辆。
--- 参数
--- direction :: defines.rail_direction
--- 返回值
--- 是否建立了任何连接。
---@return boolean ok
---@param direction defines.rail_direction
function LuaEntity:connect_rolling_stock(direction) end

--- 将设置从给定实体复制到该实体。
--- 参数
--- entity :: LuaEntity
--- 返回值
--- 因复制设置而从该实体移除的任何物品。
---@return table<string, integer> count
---@param entity LuaEntity
function LuaEntity:copy_settings(entity) end

--- 创建与手动放置建筑时相同的烟雾。可以使用 LuaSurface::play_sound 播放相应的建筑音效，例如：
--- entity.surface.play_sound{path="entity-build/"..entity.prototype.name, position=entity.position}
function LuaEntity:create_build_effect_smoke(...) end

--- 对实体造成伤害。
--- 参数
--- damage :: float：要造成的伤害量
--- force :: ForceSpecification：造成伤害的势力。
--- type :: string（可选）：要造成的伤害类型。
--- 返回值
--- 经过抗性削减后实际造成的总伤害。
--- 仅当这是有生命的实体（EntityWithHealth）时可用。
---@return number count
---@param damage number 要造成的伤害量。
---@param force table 将要造成伤害的势力。
---@param type string? 要造成的伤害类型。
function LuaEntity:damage(damage, force, type) end

--- 摧毁该实体。
--- 参数
--- opts（可选）：包含以下字段的表：
--- do_cliff_correction :: boolean（可选）：是否应修正相邻的悬崖。默认为 false。
--- raise_destroy :: boolean（可选）：如果为 true，将调用 defines.events.script_raised_destroy。
--- 返回值
--- 实体是否确实被摧毁。
--- 注意： 并非所有实体都能被摧毁——例如火车底下的铁轨在火车移动或摧毁前无法被摧毁。
---@return boolean ok
---@param opts boolean? 包含以下字段的表：
do_cliff_correction :: boolean（可选）：是否应修正相邻的悬崖（cliff）。默认为 false。
raise_destroy :: boolean（可选）：若为 true，将调用 defines.events.script_raised_destroy。
function LuaEntity:destroy(opts) end

--- 立即杀死该实体。不关心该实体是否可摧毁或可伤害。如果实体没有生命值则不做任何事。
--- 与 LuaEntity::destroy 不同，die 会触发 on_entity_died 事件，并且如果实体有战利品和尸体则会掉落它们。
--- 参数
--- force :: ForceSpecification：击杀归属的势力。
--- cause :: LuaEntity（可选）：击杀归属的原因实体。
--- 返回值
--- 实体是否被杀死。
--- 注意： 如果只想提供原因实体，请为 force 传入 nil。
---@return boolean ok
---@param cause LuaEntity? 击杀所归因的原因实体。
---@param force table 击杀所归因的势力。
function LuaEntity:die(cause, force) end

--- 关闭手电筒。
function LuaEntity:disable_flashlight(...) end

--- 断开导线或电缆。
--- 参数
--- target :: defines.wire_type 或 LuaEntity 或 table（可选）。
--- 要移除所有铜缆，请省略此参数：pole.disconnect_neighbour()。
--- 要移除特定颜色的所有导线，请传入 defines.wire_type.red 或 defines.wire_type.green。
--- 要移除两个电线杆之间的特定铜缆，target 可以是 LuaEntity，指定另一个电线杆。例如：pole1.disconnect_neighbour(pole2)。
--- 要移除特定的红色或绿色导线，请传入与 LuaEntity::connect_neighbour 相同格式的表：
--- wire :: defines.wire_type：电线颜色
--- target_entity :: LuaEntity
--- source_circuit_id :: uint（可选）
--- target_circuit_id :: uint（可选）
---@param target defines.wire_type | LuaEntity | table? ````
pole.disconnect_neighbour()````
要移除特定颜色的所有电线，请传入 defines.wire_type.red 或 defines.wire_type.green。
要移除两根电线杆之间的特定铜线，target 可以是 LuaEntity，用于指定另一根电线杆。例如：````
pole1.disconnect_neighbour(pole2)````
。
要移除特定的红色或绿色电线，请传入与 LuaEntity::connect_neighbour 相同格式的表：
wire :: defines.wire_type：电线颜色
target_entity :: LuaEntity
source_circuit_id :: uint（可选）
target_circuit_id :: uint（可选）
function LuaEntity:disconnect_neighbour(target) end

--- 尝试沿给定方向断开此机车车辆。
--- 参数
--- direction :: defines.rail_direction
--- 返回值
--- 是否有任何连接被断开。
---@return boolean ok
---@param direction defines.rail_direction
function LuaEntity:disconnect_rolling_stock(direction) end

--- 打开手电筒。
function LuaEntity:enable_flashlight(...) end

--- 获取此光束（beam）的来源。
--- 仅当这是光束（Beam）时可用。
---@return table result
function LuaEntity:get_beam_source(...) end

--- 获取此光束的目标。
--- 仅当这是光束（Beam）时可用。
---@return table result
function LuaEntity:get_beam_target(...) end

--- 此实体的燃烧结果（burnt result）物品栏；如果该实体没有燃烧结果物品栏则为 nil。
---@return LuaInventory result
function LuaEntity:get_burnt_result_inventory(...) end

--- 参数
--- wire :: defines.wire_type：连接到该实体的网络的电线颜色。
--- circuit_connector :: defines.circuit_connector_id（可选）：要获取电路网络的连接器；对于拥有多个电路网络连接器的实体必须指定。
--- 返回值
--- 电路网络或 nil。
---@return LuaCircuitNetwork result
---@param circuit_connector defines.circuit_connector_id? 要获取其电路网络的连接器。
对于拥有多个电路网络连接器的实体，必须指定此项。
---@param wire defines.wire_type 连接到此实体的网络的导线颜色。
function LuaEntity:get_circuit_network(circuit_connector, wire) end

--- 参数
--- 包含以下字段的表：
--- rail_direction :: defines.rail_direction
--- rail_connection_direction :: defines.rail_connection_direction
--- 返回值
--- 以指定方式连接到该铁轨的铁轨。
--- 仅当这是铁轨（Rail）时可用。
---@return LuaEntity entity
---@param rail_direction defines.rail_direction rail_direction :: defines.rail_direction
rail_connection_direction :: defines.rail_connection_direction
function LuaEntity:get_connected_rail(rail_direction) end

--- 获取此信号灯连接到的铁轨。
--- 仅当这是铁路信号灯（RailSignal）时可用。
---@return LuaEntity[] entity
function LuaEntity:get_connected_rails(...) end

--- 获取实体的控制行为（如果有）。
--- 返回值
--- 控制行为或 nil。
---@return LuaControlBehavior result
function LuaEntity:get_control_behavior(...) end

--- 获取给定配方可以制作的数量。
--- 参数
--- recipe :: string 或 LuaRecipe：配方。
--- 返回值
--- 可以制作的数量。
---@return integer count
---@param recipe string | LuaRecipe 配方。
function LuaEntity:get_craftable_count(recipe) end

--- 获取此载具的驾驶员（如果有）。
--- 注意： 如果载具没有驾驶员则可能为 nil。要检查是否有乘客，请参见 LuaEntity::get_passenger。
--- 仅当这是载具（Vehicle）时可用。
---@return LuaEntity | LuaPlayer result
function LuaEntity:get_driver(...) end

--- 获取机械臂或装卸机中某个栏位的过滤器。
--- 参数
--- uint：要获取过滤器的栏位。
--- 返回值
--- 被过滤物品的原型名称；如果给定栏位没有过滤器则为 nil。
--- 注意： 机械臂/装卸机必须允许过滤器。
---@return string result
---@param _uint integer 要获取其过滤器（filter）的槽位。
function LuaEntity:get_filter(_uint) end

--- 获取该实体中所有流体的数量。
--- 返回值
--- 数量，以流体名称作为索引。
---@return table<string, number> count
function LuaEntity:get_fluid_contents(...) end

--- 获取该实体中所有或部分流体的数量。
--- 参数
--- fluid :: string（可选）：要计数的流体的原型名称。如果未指定，则计数所有流体。
---@return number count
---@param fluid string? 要计数的流体的原型名称。若未指定，则统计所有流体。
function LuaEntity:get_fluid_count(fluid) end

--- 此实体的燃料物品栏；如果该实体没有燃料物品栏则为 nil。
---@return LuaInventory result
function LuaEntity:get_fuel_inventory(...) end

--- 此实体的生命值比例，介于 1 和 0 之间（分别对应满血和空血）。
---@return number count
function LuaEntity:get_health_ratio(...) end

--- 获取此热接口（heat interface）的热量设置。
--- 仅当这是热接口（HeatInterface）时可用。
---@return table result
function LuaEntity:get_heat_setting(...) end

--- 获取此无限容器（infinity container）在给定索引处的过滤器；如果过滤器索引不存在或为空则为 nil。
--- 参数
--- index :: uint：要获取的索引。
--- 仅当这是无限容器（InfinityContainer）时可用。
---@return table result
---@param index integer 要获取的索引。
function LuaEntity:get_infinity_container_filter(index) end

--- 获取此无限管道（infinity pipe）的过滤器；如果过滤器为空则为 nil。
--- 仅当这是无限管道（InfinityPipe）时可用。
---@return table result
function LuaEntity:get_infinity_pipe_filter(...) end

--- 获取属于该实体的物品栏。这可以是"主"物品栏，也可以是某些辅助物品栏，例如插件模块栏位或物流垃圾栏位。
--- 参数
--- inventory :: defines.inventory
--- 返回值
--- 如果该实体没有具有给定索引的物品栏则为 nil。
--- 注意： 给定的 defines.inventory 仅对相应的 LuaObject 类型有意义。例如：get_inventory(defines.inventory.character_main) 仅在"this"是玩家角色时有意义。你可能会得到一个返回值，但如果"this"的类型不是 defines.inventory 所指的类型，那么几乎可以确定它不是所请求的物品栏。
---@return LuaInventory result
---@param inventory defines.inventory
function LuaEntity:get_inventory(inventory) end

--- 获取该实体中所有或部分物品的数量。
--- 参数
--- item :: string（可选）：要计数的物品的原型名称。如果未指定，则计数所有物品。
---@return integer count
---@param item string? 要计数的物品的原型名称。如果未指定，则统计所有物品。
function LuaEntity:get_item_count(item) end

--- 获取由给定索引指定的 LuaLogisticPoint；如果未给定索引，则返回该实体拥有的所有物流点。
--- 参数
--- defines.logistic_member_index（可选）
--- 注意： 对于大多数实体，未给定索引时这将是一个单项。对于某些实体（如玩家角色），这可以是零个或多个。
---@return LuaLogisticPoint | LuaLogisticPoint[] result
---@param _defines_logistic_member_index defines.logistic_member_index?
function LuaEntity:get_logistic_point(_defines_logistic_member_index) end

--- 如果这是角色或玩家，则获取该角色或玩家的主物品栏。
--- 返回值
--- 如果该实体不是角色或玩家则为 nil。
---@return LuaInventory result
function LuaEntity:get_main_inventory(...) end

--- 获取市场中的所有报价，作为数组。
--- 仅当这是市场（Market）时可用。
---@return table[] result
function LuaEntity:get_market_items(...) end

--- 获取传送带或可连接传送带实体的最大传送线索引。
--- 仅当这是可连接传送带实体（TransportBeltConnectable）时可用。
---@return integer count
function LuaEntity:get_max_transport_line_index(...) end

--- 合并后的电路网络信号；如果没有信号则为 nil。
--- 参数
--- circuit_connector :: defines.circuit_connector_id（可选）：要获取信号的连接器；对于拥有多个电路网络连接器的实体必须指定。
--- 返回值
--- 红色和绿色网络上的信号总和；如果它没有电路连接器则为 nil。
---@return table[] result
---@param circuit_connector defines.circuit_connector_id? 要获取信号的连接器。
对于拥有多个电路网络连接器的实体，必须指定此参数。
function LuaEntity:get_merged_signals(circuit_connector) end

--- 返回值
--- 用于存储该实体插件模块的物品栏；如果该实体没有插件模块物品栏则为 nil。
---@return LuaInventory result
function LuaEntity:get_module_inventory(...) end

--- 获取（如有需要则创建）实体的控制行为。
--- 返回值
--- 控制行为或 nil。
---@return LuaControlBehavior result
function LuaEntity:get_or_create_control_behavior(...) end

--- 如果实体有输出物品栏，则获取其输出物品栏。
--- 返回值
--- 对实体输出物品栏的引用。
---@return LuaInventory result
function LuaEntity:get_output_inventory(...) end

--- 获取此汽车的乘客（如果有）。
--- 注意： 如果载具没有乘客则可能为 nil。要检查是否有驾驶员，请参见 LuaEntity::get_driver。
--- 注意： 这与 LuaEntity::get_driver 不同，乘客不能驾驶汽车。
--- 仅当这是汽车（Car）时可用。
---@return LuaEntity | LuaPlayer result
function LuaEntity:get_passenger(...) end

--- 此实体的半径。
---@return number count
function LuaEntity:get_radius(...) end

--- 获取该铁轨所在的铁轨段末端的铁轨。
--- 参数
--- direction :: defines.rail_direction
--- 注意： 铁轨段是没有分支、信号灯或火车站的连续铁轨区段。
--- 注意： 此函数有第二个返回值：一个 defines.rail_direction，指向从末端铁轨离开铁轨段的方向。
--- 仅当这是铁轨（Rail）时可用。
---@return LuaEntity entity
---@param direction defines.rail_direction
function LuaEntity:get_rail_segment_end(direction) end

--- 获取该铁轨所在的铁轨段起点/终点的铁路信号灯或火车站；如果铁轨段不是以信号灯或火车站开头/结尾则为 nil。
--- 参数
--- direction :: defines.rail_direction：相对于该铁轨的行驶方向。
--- in_else_out :: boolean：如果为 true，获取铁轨段入口处的实体，否则获取铁轨段出口处的实体。
--- 注意： 铁轨段是没有分支、信号灯或火车站的连续铁轨区段。
--- 仅当这是铁轨（Rail）时可用。
---@return LuaEntity entity
---@param direction defines.rail_direction 相对于此铁轨的行进方向。
---@param in_else_out boolean 若为 true，则获取该铁轨段入口处的实体；否则获取该铁轨段出口处的实体。
function LuaEntity:get_rail_segment_entity(direction, in_else_out) end

--- 获取该铁轨所在的铁轨段的长度。
--- 注意： 铁轨段是没有分支、信号灯或火车站的连续铁轨区段。
--- 仅当这是铁轨（Rail）时可用。
---@return number count
function LuaEntity:get_rail_segment_length(...) end

--- 从每个与该铁轨的铁轨段重叠的铁轨段中获取一条铁轨。
--- 注意： 铁轨段是没有分支、信号灯或火车站的连续铁轨区段。
--- 仅当这是铁轨（Rail）时可用。
---@return LuaEntity[] entity
function LuaEntity:get_rail_segment_overlaps(...) end

--- 此机器当前正在组装的配方；如果没有设置配方则为 nil。
--- 仅当这是制造机（CraftingMachine）时可用。
---@return LuaRecipe recipe
function LuaEntity:get_recipe(...) end

--- 获取物流请求栏位。
--- 参数
--- slot :: uint：栏位索引。
--- 返回值
--- 指定栏位的内容；如果给定栏位没有请求则为 nil。
--- 注意： 仅可用于拥有请求栏位的实体。
---@return table result
---@param slot integer 栏位（slot）索引。
function LuaEntity:get_request_slot(slot) end

--- 当前停靠在此火车站的火车；如果没有则为 nil。
--- 仅当这是火车站（TrainStop）时可用。
---@return LuaTrain train
function LuaEntity:get_stopped_train(...) end

--- 计划停靠在此火车站的火车。
--- 仅当这是火车站（TrainStop）时可用。
---@return LuaTrain[] train
function LuaEntity:get_train_stop_trains(...) end

--- 获取传送带或可连接传送带实体的传送线。
--- 参数
--- index :: uint：所请求传送线的索引。
--- 仅当这是可连接传送带实体（TransportBeltConnectable）时可用。
---@return LuaTransportLine result
---@param index integer 所请求的运输线（transport line）的索引。
function LuaEntity:get_transport_line(index) end

--- 与 LuaEntity::has_flag 相同，但目标是实体虚影（entity ghost）上的内部实体。
--- 参数
--- flag :: string：要测试的标志。
--- 返回值
--- 如果实体设置了给定标志则返回 true。
---@return boolean ok
---@param flag string 要测试的标志（flag）。
function LuaEntity:ghost_has_flag(flag) end

--- 此单位是否已被分配命令。
--- 仅当这是单位（Unit）时可用。
---@return boolean ok
function LuaEntity:has_command(...) end

--- 测试该实体的原型是否设置了标志。
--- 参数
--- flag :: string：要测试的标志。
--- 返回值
--- 如果实体设置了给定标志则返回 true。
--- 注意： entity.has_flag(f) 是 entity.prototype.has_flag(f) 的快捷方式。
---@return boolean ok
---@param flag string 要测试的标志（flag）。
function LuaEntity:has_flag(flag) end

--- 该实体内部是否有任何物品？
---@return boolean ok
function LuaEntity:has_items_inside(...) end

--- 向该实体插入物品。这与机械臂或 Shift 点击的工作方式相同：自动选择"最佳"物品栏。
--- 参数
--- items :: ItemStackSpecification：要插入的物品。
--- 返回值
--- 实际插入的物品数量。
---@return integer count
---@param items table 要插入的物品。
function LuaEntity:insert(items) end

--- 向该实体插入流体。自动选择流体箱。
--- 参数
--- fluid :: Fluid：要插入的流体。
--- 返回值
--- 实际插入的流体数量。
---@return number count
---@param fluid table 要插入的流体。
function LuaEntity:insert_fluid(fluid) end

--- 返回值
--- 如果此大门当前已关闭则返回 true。
--- 仅当这是大门（Gate）时可用。
---@return boolean ok
function LuaEntity:is_closed(...) end

--- 返回值
--- 如果此大门当前正在关闭则返回 true。
--- 仅当这是大门（Gate）时可用。
---@return boolean ok
function LuaEntity:is_closing(...) end

--- 如果此实体已连接到电力网络则返回 true。
---@return boolean ok
function LuaEntity:is_connected_to_electric_network(...) end

--- 返回值
--- 如果此机器当前正在制作则返回 true。
--- 仅当这是制造机（CraftingMachine）时可用。
---@return boolean ok
function LuaEntity:is_crafting(...) end

--- 返回值
--- 如果此大门当前已打开则返回 true。
--- 仅当这是大门（Gate）时可用。
---@return boolean ok
function LuaEntity:is_opened(...) end

--- 返回值
--- 如果此大门当前正在打开则返回 true。
--- 仅当这是大门（Gate）时可用。
---@return boolean ok
function LuaEntity:is_opening(...) end

--- 当为 true 时，控制适配器是 LuaPlayer 对象；对于包括带玩家的角色在内的实体为 false。
---@return boolean ok
function LuaEntity:is_player(...) end

--- 返回值
--- 如果火箭成功发射则返回 true。
--- 返回 false 意味着发射井尚未准备好发射。
--- 仅当这是火箭发射井（RocketSilo）时可用。
---@return boolean ok
function LuaEntity:launch_rocket(...) end

--- 像此玩家（或角色）开采一样开采给定实体。
--- 参数
--- entity :: LuaEntity：要开采的实体。
--- force :: boolean（可选）：即使物品无法放入玩家物品栏，也强制开采该实体。
--- 返回值
--- 开采是否成功。
---@return boolean ok
---@param entity LuaEntity 要开采的实体。
---@param force boolean? 即使物品无法放入玩家（背包）中，也强制开采该实体。
function LuaEntity:mine_entity(entity, force) end

--- 像此玩家（或角色）开采一样开采给定地块。
--- 参数
--- tile :: LuaTile：要开采的地块。
--- 返回值
--- 开采是否成功。
---@return boolean ok
---@param tile LuaTile 要开采的地块（tile）。
function LuaEntity:mine_tile(tile) end

--- 打开科技界面（GUI）并选择给定的科技。
--- 参数
--- technology :: TechnologySpecification（可选）：打开界面后要选择的科技。
---@param technology table? 打开界面（GUI）后要选择的科技。
function LuaEntity:open_technology_gui(technology) end

--- 设置该实体由建造机器人（construction robot）拆除。
--- 参数
--- force :: ForceSpecification：其机器人负责执行拆除的势力。
--- player :: PlayerSpecification（可选）：如果有的话，要设置为 last_user 的玩家。
--- 返回值
--- 实体是否被标记为拆除。
---@return boolean ok
---@param force table 其机器人（robots）应执行拆除（deconstruction）的势力。
---@param player table? 要将其设置为 last_user 的玩家（如果有）。
function LuaEntity:order_deconstruction(force, player) end

--- 设置该实体由建造机器人升级。
--- 参数
--- 包含以下字段的表：
--- force :: ForceSpecification：其机器人负责执行升级的势力。
--- target :: EntityPrototypeSpecification：要升级到的实体的原型。
--- player :: PlayerSpecification（可选）
--- 返回值
--- 实体是否被标记为升级。
---@return boolean ok
---@param force table? force :: ForceSpecification：其机器人应执行升级（upgrade）的势力。
target :: EntityPrototypeSpecification：要升级为的实体的原型（prototype）。
player :: PlayerSpecification（可选）
function LuaEntity:order_upgrade(force) end

--- 用给定的乐器和音符播放一个音符。
--- 参数
--- instrument :: uint
--- note :: uint
--- 返回值
--- 请求是否有效。根据复音（polyphony）设置，声音可能会播放也可能不会播放。
--- 仅当这是可编程扬声器（ProgrammableSpeaker）时可用。
---@return boolean ok
---@param instrument integer
---@param note integer
function LuaEntity:play_note(instrument, note) end

--- 将单位从其产生的巢穴（spawner）中释放。这允许巢穴继续产生更多单位。
--- 仅当这是单位（Unit）时可用。
function LuaEntity:release_from_spawner(...) end

--- 从该实体移除流体。
--- 参数
--- 包含以下字段的表：
--- name :: string：流体原型名称。
--- amount :: double：要移除的数量
--- minimum_temperature :: double（可选）
--- maximum_temperature :: double（可选）
--- temperature :: double（可选）
--- 返回值
--- 实际移除的流体数量。
--- 注意： 如果给出了 temperature，则只移除与该确切温度匹配的流体。如果给出了 minimum 和 maximum，则移除该范围内的流体。
---@return number count
---@param name string? name :: string：流体原型名称。
amount :: double：要移除的数量
minimum_temperature :: double（可选）
maximum_temperature :: double（可选）
temperature :: double（可选）
function LuaEntity:remove_fluid(name) end

--- 从该实体移除物品。
--- 参数
--- items :: ItemStackSpecification：要移除的物品。
--- 返回值
--- 实际移除的物品数量。
---@return integer count
---@param items table 要移除的物品。
function LuaEntity:remove_item(items) end

--- 从市场移除一个报价。
--- 参数
--- offer :: uint：要移除的报价索引。
--- 返回值
--- 如果报价被成功移除则返回 true；当给定索引无效时返回 false。
--- 注意： 其他报价会下移以填补移除报价产生的空位，这会减少报价数组的总大小。
--- 仅当这是市场（Market）时可用。
---@return boolean ok
---@param offer integer 要移除的报价（offer）的索引。
function LuaEntity:remove_market_item(offer) end

--- 参数
--- force :: ForceSpecification：请求关闭大门的势力。
--- 仅当这是大门（Gate）时可用。
---@param force table 请求关闭闸门（gate）的势力。
function LuaEntity:request_to_close(force) end

--- 参数
--- force :: ForceSpecification：请求打开大门的势力。
--- extra_time :: uint（可选）：额外保持打开的 tick 数。
--- 仅当这是大门（Gate）时可用。
---@param extra_time integer? 额外保持开启的 tick 数。
---@param force table 请求打开闸门（gate）的势力。
function LuaEntity:request_to_open(extra_time, force) end

--- 复活虚影。即将其从虚影变成真实实体或地块。
--- 参数
--- opts（可选）：包含以下字段的表：
--- return_item_request_proxy :: boolean（可选）：如果为 true，函数将返回物品请求代理作为第三个参数。
--- raise_revive :: boolean（可选）：如果为 true，将调用 defines.events.script_raised_revive。
--- 返回值
--- 新真实实体碰撞到的任何物品；如果虚影无法被复活则为 nil。
--- 注意： 如果这是实体虚影且成功复活，还将返回复活的实体或 nil 作为第二个返回值；并且根据 return_item_request_proxy 的值，可能将物品请求代理作为第三个参数返回。
---@return table<string, integer> count
---@param opts boolean? 包含以下字段的表：
return_item_request_proxy :: boolean（可选）：若为 ````
true````
，该函数将把物品请求代理（item request proxy）作为第三个参数返回。
raise_revive :: boolean（可选）：若为 true，将调用 defines.events.script_raised_revive。
function LuaEntity:revive(opts) end

--- 像玩家旋转一样旋转该实体。
--- 参数
--- options（可选）：包含以下字段的表：
--- reverse :: boolean（可选）
--- by_player :: LuaPlayer（可选）
--- spill_items :: boolean（可选）：如果未给出玩家，多余的物品是应该被洒出还是作为此函数的第二个返回值返回。
--- enable_looted :: boolean（可选）：为 true 时，每个洒出的物品都将被标记上 LuaEntity::to_be_looted 标志。
--- force :: LuaForce 或 string（可选）：提供时，洒出的物品将被标记为由该势力拆除。
--- 返回值
--- 旋转是否成功。
---@return boolean ok
---@param options boolean? 包含以下字段的表：
reverse :: boolean（可选）
by_player :: LuaPlayer（可选）
spill_items :: boolean（可选）：若未指定 player，多余物品应散落出来（spill），还是作为本函数的第二个返回值返回。
enable_looted :: boolean（可选）：若为 true，每个散落的物品都会被标记上 LuaEntity::to_be_looted 标志。
force :: LuaForce 或 string（可选）：若提供，散落的物品将被标记为由该势力执行拆除（deconstruction）。
function LuaEntity:rotate(options) end

--- 设置此光束的来源。
--- 参数
--- source :: LuaEntity 或 Position
--- 仅当这是光束（Beam）时可用。
---@param source LuaEntity | table
function LuaEntity:set_beam_source(source) end

--- 设置此光束的目标。
--- 参数
--- target :: LuaEntity 或 Position
--- 仅当这是光束（Beam）时可用。
---@param target LuaEntity | table
function LuaEntity:set_beam_target(target) end

--- 给实体下达命令。
--- 参数
--- command :: Command
--- 仅当这是单位（Unit）时可用。
---@param command table
function LuaEntity:set_command(command) end

--- 设置此载具的驾驶员。
--- 参数
--- driver :: LuaEntity 或 LuaPlayer：新驾驶员；或 nil 以弹出当前驾驶员（如果有）。
--- 注意： 这与 LuaEntity::set_passenger 不同，乘客不能驾驶载具。
--- 仅当这是载具（Vehicle）时可用。
---@param driver LuaEntity | LuaPlayer 新的乘客（passenger），或传入 ````
nil````
以弹出当前的驾驶员（driver）（如果有）。
function LuaEntity:set_driver(driver) end

--- 设置机械臂或装卸机中某个栏位的过滤器。
--- 参数
--- uint：要设置过滤器的栏位。
--- string：要过滤的物品的原型名称。
--- 注意： 机械臂/装卸机必须允许过滤器。
---@param _string string 要过滤的物品的原型名称。
---@param _uint integer 要设置其过滤器（filter）的槽位。
function LuaEntity:set_filter(_string, _uint) end

--- 创建一个指向该实体的箭头。这用于教程。示例请参见战役任务中的 control.lua。
--- 参数
--- 包含以下字段的表：
--- type :: string：指向哪里。此字段决定哪些其他字段是必需的。可以是 "nowhere"、"goal"、"entity_info"、"active_window"、"entity"、"position"、"crafting_queue" 或 "item_stack"。
--- 其他 type 特定参数：
--- entity：entity :: LuaEntity
--- position：position :: Position
--- crafting_queue：crafting_queue index :: uint
--- item_stack：inventory_index :: defines.inventory、item_stack_index :: uint
--- source :: string：可以是 "player" 或 "target"。
---@param type string 包含以下字段的表：
type :: [string]：指向的位置。此字段决定哪些其他字段是必需的。可以是 "nowhere"、"goal"、"entity_info"、"active_window"、"entity"、"position"、"crafting_queue" 或 "item_stack"。
附加的 type 专属参数：
entity
entity :: [LuaEntity]
position
position :: [Position]
crafting_queue
crafting_queue index :: [uint]
item_stack
inventory_index :: [defines.inventory]
item_stack_index :: [uint]
source :: [string]：可以是 "player" 或 "target"。
function LuaEntity:set_gui_arrow(type) end

--- 设置此热接口的热量设置。
--- 参数
--- filter :: HeatSetting：新设置。
--- 仅当这是热接口（HeatInterface）时可用。
---@param filter table 新的设置。
function LuaEntity:set_heat_setting(filter) end

--- 在此无限容器的给定索引处设置过滤器。
--- 参数
--- index :: uint：要设置的索引。
--- filter :: InfinityContainerFilter：新过滤器；或 nil 以清除过滤器。
--- 仅当这是无限容器（InfinityContainer）时可用。
---@param filter table 新的过滤器，或传入 ````
nil````
以清除过滤器。
---@param index integer 要设置的索引。
function LuaEntity:set_infinity_container_filter(filter, index) end

--- 设置此无限管道的过滤器。
--- 参数
--- filter :: InfinityPipeFilter：新过滤器；或 nil 以清除过滤器。
--- 仅当这是无限管道（InfinityPipe）时可用。
---@param filter table 新的过滤器，或传入 ````
nil````
以清除过滤器。
function LuaEntity:set_infinity_pipe_filter(filter) end

--- 设置此汽车的乘客。
--- 参数
--- passenger :: LuaEntity 或 LuaPlayer
--- 注意： 这与 LuaEntity::get_driver 不同，乘客不能驾驶汽车。
--- 仅当这是汽车（Car）时可用。
---@param passenger LuaEntity | LuaPlayer
function LuaEntity:set_passenger(passenger) end

--- 在此组装机中设置当前配方。
--- 参数
--- recipe :: string 或 LuaRecipe：新配方；或 nil 以清除配方。
--- 返回值
--- 因设置配方而从该实体移除的任何物品。
--- 仅当这是制造机（CraftingMachine）时可用。
---@return table<string, integer> count
---@param recipe string | LuaRecipe 新的配方，或传入 ````
nil````
以清除配方。
function LuaEntity:set_recipe(recipe) end

--- 设置物流请求栏位。
--- 参数
--- request :: ItemStackSpecification：要请求什么。
--- slot :: uint：栏位索引。
--- 注意： 仅可用于拥有请求栏位的实体。
---@param request table 要请求的内容。
---@param slot integer 栏位（slot）索引。
function LuaEntity:set_request_slot(request, slot) end

--- 静默复活虚影。
--- 参数
--- opts（可选）：包含以下字段的表：
--- return_item_request_proxy :: boolean（可选）：如果为 true，函数将返回物品请求代理作为第三个参数。
--- raise_revive :: boolean（可选）：如果为 true，将调用 defines.events.script_raised_revive。
--- 返回值
--- 新真实实体碰撞到的任何物品；如果虚影无法被复活则为 nil。
--- 注意： 如果这是实体虚影且成功复活，还将返回复活的实体或 nil 作为第二个返回值；并且根据 return_item_request_proxy 的值，可能将物品请求代理作为第三个参数返回。
---@return table<string, integer> count
---@param opts boolean? 包含以下字段的表：
return_item_request_proxy :: boolean（可选）：若为 ````
true````
，该函数将把物品请求代理（item request proxy）作为第三个参数返回。
raise_revive :: boolean（可选）：若为 true，将调用 defines.events.script_raised_revive。
function LuaEntity:silent_revive(opts) end

--- 返回值
--- 如果此实体支持支持者名称则返回 true。
---@return boolean ok
function LuaEntity:supports_backer_name(...) end

--- 将实体传送到给定位置，可能跨越地表。
--- 参数
--- position :: Position：要传送到的位置。
--- surface :: SurfaceSpecification（可选）：要传送到的地表。如果未给出，将传送到实体当前所在的地表。
--- 返回值
--- 实体成功传送时返回 true。
--- 注意： 某些实体可能无法被传送。例如，铁路信号灯不允许传送，此方法在用于任何此类实体时始终返回 false。
--- 注意： 你也可以传入 1 或 2 个数字作为参数，它们将被用作相对传送坐标：'teleport(0, 1)' 将实体向正方向移动 1 个地块；'teleport(4)' 将实体向正 x 方向移动 4 个地块。
---@return boolean ok
---@param position table 要传送到的位置。
---@param surface table? 要传送到的地表。如果未指定，将传送到实体当前所在的地表。
function LuaEntity:teleport(position, surface) end

--- 该实体是否被标记为拆除。
--- 参数
--- force :: ForceSpecification：下达拆除命令的势力。此参数目前未使用；它仅是为了 API 的前向兼容性而存在。
---@return boolean ok
---@param force table 下令执行拆除（deconstruction）的势力。该参数目前未被使用；它仅用于保持 API 的前向兼容性。
function LuaEntity:to_be_deconstructed(force) end

--- 该实体是否被标记为升级。
---@return boolean ok
function LuaEntity:to_be_upgraded(...) end

--- 切换该实体的装备移动加成。如果实体没有装备栏则不做任何事。
--- 注意： 此属性也可以在该实体的装备栏上读写。
function LuaEntity:toggle_equipment_movement_bonus(...) end

--- 重新连接装卸机、信标、悬崖和采矿钻机与被脚本传送出或传送入的实体的连接。游戏不会自动执行此操作，因为我们不想在正常游戏中因检查而损失性能。
function LuaEntity:update_connections(...) end

--- 选择一个实体，就像将鼠标悬停在它上方一样。
--- 参数
--- position :: Position：要选择的实体的位置。
---@param position table 要选择的实体的位置。
function LuaEntity:update_selected_entity(position) end

--- 实体的原型。
---@class LuaEntityPrototype
---@field additional_pastable_entities LuaEntityPrototype[] (只读) 除常规允许的实体之外，该实体还可以粘贴到的实体。
---@field affected_by_tiles boolean (只读) 此单位原型是否受地块行走速度修正值影响；如果没有则为 nil。
---@field alert_icon_shift table (只读) 此实体原型的警报图标偏移。
---@field alert_when_attacking boolean (只读) 此炮塔原型在攻击时是否发出警报；如果不是炮塔原型则为 nil。
---@field alert_when_damaged boolean (只读) 此有生命实体原型在受到伤害时是否发出警报；如果不是有生命实体原型则为 nil。
---@field allow_copy_paste boolean (只读) 为 false 时，不允许对此实体进行复制粘贴。
---@field allow_custom_vectors boolean (只读) 此机械臂是否允许自定义拾取和掉落向量。
---@field allowed_effects table<string, boolean> (只读) 此实体允许的插件模块效果；如果没有则为 nil。
---@field attack_parameters table (只读) 此实体的攻击参数；如果实体不使用攻击参数则为 nil。 它是一个表： range :: float min_range :: float turn_range :: float fire_penalty :: float min_attack_distance :: float damage_modifier :: float ammo_consumption_modifier :: float cooldown :: float warmup :: uint movement_slow_down_factor :: double movement_slow_down_cooldown :: float
---@field attack_result table (只读) 此实体的攻击结果（如果实体有）；否则为 nil。
---@field automated_ammo_count integer (只读) 机械臂自动插入到此弹药炮塔或火炮炮塔中的弹药数量；如果没有则为 nil。
---@field autoplace_specification table (只读) 此实体原型的自动放置（autoplace）规范；如果没有则为 nil。
---@field belt_distance number (只读) 仅当这是装卸机（Loader）时可用。
---@field belt_length number (只读) 仅当这是装卸机（Loader）时可用。
---@field belt_speed number (只读) 此传送带的速度；如果这不是与传送带相关的原型则为 nil。
---@field braking_force number (只读) 此载具原型的制动力；如果不是载具原型则为 nil。
---@field build_base_evolution_requirement number (只读) 在扩展敌方基地时，将此实体建造成基地所需的进化（evolution）要求。
---@field build_distance integer (只读) 仅当这是角色（Character）时可用。
---@field building_grid_bit_shift integer (只读) 建筑网格大小的 log2。
---@field burner_prototype LuaBurnerPrototype (只读) 此实体使用的燃烧能量源原型；如果没有则为 nil。
---@field can_open_gates boolean (只读) 此单位原型能否打开大门；如果不能则为 nil。
---@field character_corpse LuaEntityPrototype (只读) 仅当这是角色（Character）时可用。
---@field cliff_explosive_prototype string (只读) 用于摧毁此悬崖的物品原型名称；如果没有则为 nil。
---@field collision_box table (只读) 用于碰撞检测的包围盒。
---@field collision_mask table (只读) 此实体使用的碰撞掩码。
---@field collision_mask_collides_with_self boolean (只读) 此原型碰撞掩码是否与其自身碰撞。
---@field collision_mask_collides_with_tiles_only boolean (只读) 此原型碰撞掩码是否仅与地块碰撞。
---@field collision_mask_considers_tile_transitions boolean (只读) 此原型碰撞掩码是否考虑地块过渡。
---@field color table (只读) 原型的颜色；如果原型没有颜色则为 nil。
---@field construction_radius number (只读) 此机器人港口（roboport）原型的建造半径；如果没有则为 nil。
---@field consumption number (只读) 此汽车原型的能量消耗；如果不是汽车原型则为 nil。
---@field container_distance number (只读) 仅当这是装卸机（Loader）时可用。
---@field corpses table<string, LuaEntityPrototype> (只读) 此实体被摧毁时使用的尸体。这是一个以尸体原型名称作为索引的字典。
---@field count_as_rock_for_filtered_deconstruction boolean (只读) 此简单实体是否被拆除规划器（deconstruction planner）的"仅树木和岩石"过滤器计为岩石。
---@field crafting_categories table<string, boolean> (只读) 此实体支持的制作类别。仅当这是制造机或玩家实体类型时才有意义。 注意： 字典中的值没有意义，仅是为了允许使用字典类型以便于查找。
---@field crafting_speed number (只读) 此制造机的制作速度；如果没有则为 nil。
---@field create_ghost_on_death boolean (只读) 此原型在死亡时是否将尝试创建自身的虚影。 注意： 如果这是 false，则永远不会创建虚影；如果为 true，则可能会创建虚影。
---@field created_effect table (只读) 此实体被创建时运行的触发器；如果没有则为 nil。
---@field created_smoke table (只读) 此实体被建造时运行的烟雾触发器；如果没有则为 nil。 它是一个表：
---@field damage_hit_tint table (只读) 仅当这是角色（Character）时可用。
---@field darkness_for_all_lamps_off number (只读) 此灯具原型所有灯都关闭时的黑暗度值（0 到 1 之间）；如果没有则为 nil。
---@field darkness_for_all_lamps_on number (只读) 此灯具原型所有灯都打开时的黑暗度值（0 到 1 之间）；如果没有则为 nil。
---@field distraction_cooldown integer (只读) 此单位原型的干扰冷却时间；如果没有则为 nil。
---@field distribution_effectivity number (只读) 此信标原型的分配效率；如果不是信标原型则为 nil。
---@field draw_cargo boolean (只读) 此物流或建造机器人飞行时是否渲染其货物；如果没有则为 nil。
---@field drawing_box table (只读) 用于绘制实体图标的包围盒。
---@field drop_item_distance integer (只读) 仅当这是角色（Character）时可用。
---@field effectivity number (只读) 此汽车原型、发电机原型的效率；如果没有则为 nil。
---@field electric_energy_source_prototype LuaElectricEnergySourcePrototype (只读) 此实体使用的电力能量源原型；如果没有则为 nil。
---@field emissions_per_second number (只读) 此实体每秒将产生的污染排放量。
---@field enemy_map_color table (只读) 绘制此实体地图时使用的敌方地图颜色。
---@field energy_per_hit_point number (只读) 此载具在碰撞期间每受到一点生命值伤害所消耗的能量；如果没有则为 nil。
---@field energy_per_move number (只读) 此飞行机器人每移动一个地块消耗的能量；如果没有则为 nil。
---@field energy_per_tick number (只读) 此飞行机器人每 tick 消耗的能量；如果没有则为 nil。
---@field energy_usage number (只读) 此实体的直接能量消耗；如果此实体没有直接能量消耗则为 nil。
---@field enter_vehicle_distance number (只读) 仅当这是角色（Character）时可用。
---@field explosion_beam number (只读) 此爆炸是否带有光束；如果不是爆炸原型则为 nil。
---@field explosion_rotate number (只读) 此爆炸是否旋转；如果不是爆炸原型则为 nil。
---@field fast_replaceable_group string (只读) 可相互快速替换的实体组。可能为 nil。
---@field filter_count integer (只读) 此机械臂、装卸机或请求箱的过滤器数量；如果没有则为 nil。
---@field final_attack_result table (只读) 弹射物（projectile）的最终攻击结果；如果不是弹射物则为 nil。
---@field fixed_recipe string (只读) 此组装机原型的固定配方名称；如果没有则为 nil。
---@field flags table (只读) 此实体的实体原型标志。
---@field fluid LuaFluidPrototype (只读) 此近海泵（offshore pump）生产的流体；如果没有则为 nil。
---@field fluid_capacity number (只读) 此实体的流体容量；如果此实体不支持流体则为 0。 注意： 制造机会报告 0，因为它们的流体容量取决于给定配方的需要。
---@field fluid_usage_per_tick number (只读) 此发电机原型的流体消耗量；如果没有则为 nil。
---@field fluidbox_prototypes LuaFluidBoxPrototype[] (只读) 此实体的流体箱原型。
---@field friction_force number (只读) 此载具原型的摩擦力；如果不是载具原型则为 nil。
---@field friendly_map_color table (只读) 绘制此实体地图时使用的友方地图颜色。
---@field group LuaGroup (只读) 此实体的组。
---@field guns table<string, LuaItemPrototype> (只读) 此汽车原型使用的武器；如果不是汽车原型则为 nil。
---@field has_belt_immunity boolean (只读) 此单位或汽车原型是否具有传送带免疫；如果不是汽车或单位原型则为 nil。
---@field healing_per_tick number (只读) 此实体每 tick 可以治疗的量。
---@field help string 此对象支持的所有方法和属性。
---@field infinite_depletion_resource_amount integer (只读) 此无限资源每次"tick"减少时减少的量。不是资源时为 nil。如果这不是无限类型的资源则没有意义。
---@field infinite_resource boolean (只读) 此资源是否是无限的？用于非资源时将为 nil。
---@field ingredient_count integer (只读) 此制造机原型支持的最大原料数量；如果这不是制造机原型则为 nil。
---@field inserter_extension_speed number (只读) 此机械臂的伸缩速度；如果没有则为 nil。
---@field inserter_rotation_speed number (只读) 此机械臂的旋转速度；如果没有则为 nil。
---@field instruments table[] (只读) 此可编程扬声器的乐器；如果没有则为 nil。
---@field is_building boolean (只读)
---@field item_pickup_distance number (只读) 仅当这是角色（Character）时可用。
---@field item_slot_count integer (只读) 此常量组合器（constant combinator）原型的物品栏位数量；如果没有则为 nil。
---@field items_to_place_this table[] (只读) 放置后会产生此实体的物品。这是一个以物品原型名称作为索引的字典。
---@field lab_inputs string[] (只读) 作为此实验室（lab）原型输入的物品原型名称；如果没有则为 nil。
---@field localised_description table (只读)
---@field localised_name table (只读)
---@field logistic_mode string (只读) 此物流容器的物流模式；如果这不是物流容器原型则为 nil。
---@field logistic_radius number (只读) 此机器人港口原型的物流半径；如果没有则为 nil。
---@field loot table (只读) 此实体被杀死时将掉落的战利品。如果没有战利品则为 nil。
---@field loot_pickup_distance number (只读) 仅当这是角色（Character）时可用。
---@field map_color table (只读) 如果未定义友方或敌方颜色，则绘制此实体地图时使用的地图颜色；如果没有则为 nil。
---@field map_generator_bounding_box table (只读) 用于地图生成器碰撞检测的包围盒。
---@field max_circuit_wire_distance number (只读) 此实体的最大电路导线距离。当实体不支持电路导线时为 0。
---@field max_darkness_to_spawn number (只读) 此单位巢穴可以产生实体的最大黑暗度。
---@field max_energy number (只读) 此飞行机器人的最大能量；如果没有则为 nil。
---@field max_energy_usage number (只读) 此实体的理论最大能量消耗。
---@field max_health number (只读) 此实体的最大生命值。如果这不是有生命的实体则为 0。
---@field max_payload_size integer (只读) 此物流或建造机器人的最大载重；如果没有则为 nil。
---@field max_polyphony integer (只读) 此可编程扬声器的最大复音数；如果没有则为 nil。
---@field max_pursue_distance number (只读) 此单位原型的最大追击距离；如果没有则为 nil。
---@field max_speed number (只读) 此弹射物（Projectile）原型的最大速度；如果没有则为 nil。
---@field max_to_charge number (只读) 此飞行机器人的最大能量，高于此值时它在停驻时不会尝试充电；如果没有则为 nil。
---@field max_underground_distance integer (只读) 地下传送带和地下管道的最大地下距离；如果这不是这些原型之一则为 nil。
---@field max_wire_distance number (只读) 此实体的最大导线距离。当实体不支持导线时为 0。
---@field maximum_corner_sliding_distance number (只读) 仅当这是角色（Character）时可用。
---@field maximum_temperature number (只读) 此发电机原型的最大流体温度；如果没有则为 nil。
---@field min_darkness_to_spawn number (只读) 此单位巢穴可以产生实体的最小黑暗度。
---@field min_pursue_time integer (只读) 此单位原型的最小追击时间；如果没有则为 nil。
---@field min_to_charge number (只读) 此飞行机器人在尝试充电前的最小能量；如果没有则为 nil。
---@field mineable_properties table (只读) 它是一个表： minable :: boolean：此实体是否可以开采？ mining_time :: double：开采一个实体所需的能量。 mining_particle :: string（可选）：开采此实体时产生的粒子的原型名称。仅当此实体在开采期间产生任何粒子时才存在。 products :: Product 数组：开采此实体获得的产物。 fluid_amount :: double（可选）：所需流体数量（如果有）。 required_fluid :: string（可选）：所需流体的原型名称（如果有）。 mining_trigger :: Trigger（可选）：开采触发器（如果有）。
---@field minimum_resource_amount integer (只读) 此资源的最小数量。用于非资源时将为 nil。
---@field mining_drill_radius number (只读) 此采矿钻机原型的开采半径；如果这不是采矿钻机原型则为 nil。
---@field mining_speed number (只读) 此采矿钻机/角色原型的开采速度；如果没有则为 nil。
---@field module_inventory_size integer (只读) 插件模块物品栏大小；如果此实体不支持插件模块则为 nil。
---@field move_while_shooting boolean (只读) 此单位原型是否可以在射击时移动；如果不能则为 nil。
---@field name string (只读) 此原型的名称。
---@field neighbour_bonus number (只读) 仅当这是反应堆（Reactor）时可用。
---@field neighbour_collision_increase number (只读) 控制反应堆连接到其他反应堆时扩展多少。 仅当这是反应堆（Reactor）时可用。
---@field next_upgrade LuaEntityPrototype (只读) 此实体的下一个升级；如果没有则为 nil。
---@field normal_resource_amount integer (只读) 此资源的正常数量。不是资源时为 nil。
---@field order string (只读) 此原型的排序字符串（order）。
---@field pollution_to_join_attack number (只读) 单位离开巢穴并攻击污染源之前，单位的巢穴必须吸收的污染量。 当原型不是单位原型时为 nil。
---@field production number (只读) 此太阳能板原型产生的最大发电量；如果没有则为 nil。
---@field pumping_speed number (只读) 此近海泵、普通泵的泵送速度；如果没有则为 nil。
---@field radar_range integer (只读) 此单位原型的雷达范围；如果没有则为 nil。
---@field radius number (只读) 此实体原型的半径。
---@field reach_distance integer (只读) 仅当这是角色（Character）时可用。
---@field reach_resource_distance number (只读) 仅当这是角色（Character）时可用。
---@field remains_when_mined LuaEntityPrototype[] (只读) 开采此实体时留下的残骸。
---@field repair_speed_modifier integer (只读) 此实体的修复速度修正值。实际修复速度将为 tool_repair_speed entity_repair_speed_modifier。可能为 nil。
---@field researching_speed number (只读) 此实验室原型的基础研究速度；如果没有则为 nil。
---@field resistances table (只读)
---@field resource_categories table<string, boolean> (只读) 此采矿钻机支持的资源类别；如果不是采矿钻机则为 nil。 注意： 字典中的值没有意义，仅是为了允许使用字典类型以便于查找。
---@field resource_category string (只读) 此资源的类别："basic-solid"、"basic-fluid" 或 nil（当不是资源时）。 注意： 在数据阶段（data stage），此属性名为 "category"。
---@field respawn_time integer (只读) 仅当这是角色（Character）时可用。
---@field result_units table[] (只读) 虫巢（biter spawner）实体的结果单位和带有权重与进化因子的出生点。每个 UnitSpawnDefinition 是一个表： unit :: string：将要产生的单位的原型名称 spawn_points :: SpawnPoint 数组：每个 SpawnPoint 是一个表： evolution_factor :: double：此权重适用的进化因子。 weight :: double：在此进化因子下产生此单位的概率。
---@field rocket_parts_required integer (只读) 此火箭发射井原型所需的火箭部件数量；如果没有则为 nil。
---@field rotation_speed number (只读) 此汽车原型的旋转速度；如果不是汽车原型则为 nil。
---@field running_speed number (只读) 仅当这是角色（Character）时可用。
---@field secondary_collision_box table (只读) 用于碰撞检测的次要包围盒；如果没有则为 nil。这仅用于铁轨和铁轨残骸。
---@field selectable_in_game boolean (只读) 此实体是否可选中？
---@field selection_box table (只读) 用于绘制选择的包围盒。
---@field selection_priority integer (只读) 此实体的选择优先级——介于 0 和 2 之间的值。
---@field shooting_cursor_size number (只读) 向此实体射击时使用的光标大小。
---@field spawn_cooldown table (只读) 此敌方巢穴原型的出生冷却时间；如果没有则为 nil。 它是一个表： min :: double max :: double
---@field spawning_time_modifier number (只读) 此单位原型的出生时间修正值；如果没有则为 nil。
---@field speed number (只读) 此飞行机器人、机车车辆、单位的默认速度；如果没有则为 nil。
---@field speed_multiplier_when_out_of_energy number (只读) 此飞行机器人能量耗尽时的速度倍率；如果没有则为 nil。
---@field stack boolean (只读) 此机械臂是否是堆叠型。
---@field sticker_box table (只读) 用于附着粘液类型实体的包围盒。
---@field subgroup LuaGroup (只读) 此实体的子组。
---@field supply_area_distance number (只读) 此电线杆、信标的供应区域；如果两者都不是则为 nil。
---@field tank_driving boolean (只读) 此汽车原型是否使用坦克式操控驾驶；如果这不是汽车原型则为 nil。
---@field target_temperature number (只读) 此锅炉（boiler）原型的目标温度；如果没有则为 nil。
---@field ticks_to_keep_aiming_direction integer (只读) 仅当这是角色（Character）时可用。
---@field ticks_to_keep_gun integer (只读) 仅当这是角色（Character）时可用。
---@field ticks_to_stay_in_combat integer (只读) 仅当这是角色（Character）时可用。
---@field time_to_live integer (只读) 此原型的存活时间；如果原型没有 time_to_live 或 time_before_remove 则为 0。
---@field timeout integer (只读) 此地面雷布设所需的时间。
---@field tree_color_count integer (只读) 如果是树，返回它支持的颜色的数量；否则为 nil。
---@field turret_range integer (只读) 此炮塔的射程；如果这不是与炮塔相关的原型则为 nil。
---@field turret_rotation_speed number (只读) 此汽车原型的炮塔旋转速度；如果不是汽车原型则为 nil。
---@field type string (只读) 此原型的类型。
---@field valid boolean (只读) 此对象是否有效？
---@field vision_distance number (只读) 此单位原型的视野距离；如果没有则为 nil。
---@field weight number (只读) 此载具原型的重量；如果不是载具原型则为 nil。
LuaEntityPrototype = {}

--- 获取此实体上给定物品栏的基础大小；如果给定物品栏不存在则为 nil。
--- 参数
--- index :: defines.inventory
---@return integer count
---@param index defines.inventory
function LuaEntityPrototype:get_inventory_size(index) end

--- 此原型是否启用了某个标志。
--- 参数
--- flag :: string：要检查的标志。必须是以下之一：
--- "not-rotatable"、"placeable-neutral"、"placeable-player"、"placeable-enemy"、"placeable-off-grid"、"player-creation"、"building-direction-8-way"、"filter-directions"、"fast-replaceable-no-build-while-moving"、"breaths-air"、"not-repairable"、"not-on-map"、"not-deconstructable"、"not-blueprintable"、"hide-from-bonus-gui"、"hide-alt-info"、"fast-replaceable-no-cross-type-while-moving"、"no-gap-fill-while-building"、"not-flammable"、"no-automated-item-removal"、"no-automated-item-insertion"、"not-upgradable"。
---@return boolean ok
---@param flag string 要检查的标志（flag）。必须是以下之一：
````
"not-rotatable"````
````
"placeable-neutral"````
````
"placeable-player"````
````
"placeable-enemy"````
````
"placeable-off-grid"````
````
"player-creation"````
````
"building-direction-8-way"````
````
"filter-directions"````
````
"fast-replaceable-no-build-while-moving"````
````
"breaths-air"````
````
"not-repairable"````
````
"not-on-map"````
````
"not-deconstructable"````
````
"not-blueprintable"````
````
"hide-from-bonus-gui"````
````
"hide-alt-info"````
````
"fast-replaceable-no-cross-type-while-moving"````
````
"no-gap-fill-while-building"````
````
"not-flammable"````
````
"no-automated-item-removal"````
````
"no-automated-item-insertion"````
````
"not-upgradable"````
function LuaEntityPrototype:has_flag(flag) end

--- 动力装甲中的一件装备。
---@class LuaEquipment
---@field burner LuaBurner (只读) 此装备的燃烧能量源；如果没有则为 nil。
---@field energy number 当前可用能量。
---@field generator_power number (只读) 每 tick 产生的能量。
---@field help string 此对象支持的所有方法和属性。
---@field max_energy number (只读) 此装备可以存储的最大能量。
---@field max_shield number (只读) 最大护盾值。
---@field max_solar_power number (只读) 最大太阳能发电量。
---@field movement_bonus number (只读) 移动速度加成。
---@field name string (只读) 此装备的名称。
---@field position table (只读) 此装备在装备栏（equipment grid）中的位置。
---@field prototype LuaEquipmentPrototype (只读)
---@field shape table (只读) 此装备的形状。它是一个表： width :: uint height :: uint
---@field shield number 装备当前的护盾值。 注意： 不能设置为高于 LuaEquipment::max_shield。
---@field type string (只读) 此装备的类型。
---@field valid boolean (只读) 此对象是否有效？
LuaEquipment = {}

--- 装备栏（equipment grid）是动力装甲的内部。
---@class LuaEquipmentGrid
---@field available_in_batteries number (只读) 装备栏中所有电池存储的总能量。
---@field battery_capacity number (只读) 装备栏中所有电池的总能量存储容量。
---@field equipment LuaEquipment[] (只读) 此装备栏中的所有装备。
---@field generator_energy number (只读) 此装备栏内装备每 tick 产生的总能量。
---@field height integer (只读) 装备栏的高度。
---@field help string 此对象支持的所有方法和属性。
---@field inhibit_movement_bonus boolean 如果此移动加成装备已关闭则为 true，否则为 false。
---@field max_shield number (只读) 此装备栏拥有的最大护盾量。
---@field max_solar_energy number (只读) 装备栏中任何太阳能板每 tick 可以产生的最大能量。实际产生的能量取决于日光水平。
---@field prototype LuaEquipmentGridPrototype (只读)
---@field shield number (只读) 此装备栏拥有的护盾量。
---@field valid boolean (只读) 此对象是否有效？
---@field width integer (只读) 装备栏的宽度。
LuaEquipmentGrid = {}

--- 检查移动一件装备是否会成功。
--- 参数
--- 包含以下字段的表：
--- equipment :: LuaEquipment：要移动的装备
--- position :: Position：放置位置
---@return boolean ok
---@param equipment LuaEquipment equipment :: LuaEquipment：要移动的装备（equipment）
position :: Position：放置位置
function LuaEquipmentGrid:can_move(equipment) end

--- 清除装备栏中的所有装备。即移除它们而不实际归还。
function LuaEquipmentGrid:clear(...) end

--- 根据位置在装备栏中查找装备。
--- 参数
--- position :: Position：位置
--- 返回值
--- 找到的装备；如果在给定位置找不到装备则为 nil。
---@return LuaEquipment equipment
---@param position table 位置
function LuaEquipmentGrid:get(position) end

--- 获取此装备栏中所有装备的数量。
--- 返回值
--- 数量，以装备名称作为索引。
---@return table<string, integer> count
function LuaEquipmentGrid:get_contents(...) end

--- 在此装备栏内移动一件装备。
--- 参数
--- 包含以下字段的表：
--- equipment :: LuaEquipment：要移动的装备
--- position :: Position：放置位置
--- 返回值
--- 如果装备成功移动则返回 true。
---@return boolean ok
---@param equipment LuaEquipment equipment :: LuaEquipment：要移动的装备（equipment）
position :: Position：放置位置
function LuaEquipmentGrid:move(equipment) end

--- 将一件装备插入装备栏。
--- 参数
--- 包含以下字段的表：
--- name :: string：装备原型名称
--- position :: Position（可选）：放置装备的网格位置。
--- 返回值
--- 新添加的装备；如果装备无法添加则为 nil。
---@return LuaEquipment equipment
---@param name string? name :: string：装备原型名称
position :: Position（可选）：放置装备的网格（grid）位置。
function LuaEquipmentGrid:put(name) end

--- 从装备栏中移除一件装备。
--- 参数
--- 包含以下字段的表：
--- position :: Position（可选）：取出包含此网格位置的装备。
--- equipment :: LuaEquipment（可选）：取出这件确切的装备。
--- 必须指定 position 或 equipment 之一。
--- 返回值
--- 被移除的装备；如果没有移除任何装备则为 nil。
---@return table result
---@param position table? position :: Position（可选）：获取网格中包含此位置的装备。
equipment :: LuaEquipment（可选）：获取此精确装备。
必须指定 `position` 或 `equipment` 其中之一。
function LuaEquipmentGrid:take(position) end

--- 从装备栏中移除所有装备。
--- 返回值
--- 每种被移除装备的数量，以它们的原型名称作为索引。
---@return table<string, integer> count
function LuaEquipmentGrid:take_all(...) end

--- 装备栏（equipment grid）的原型。
---@class LuaEquipmentGridPrototype
---@field equipment_categories string[] (只读) 可插入此装备栏的类别的装备类别名称。此装备栏将接受任何在此列表中至少有一个类别的装备。 另请参阅 LuaEquipmentPrototype::equipment_categories
---@field height integer (只读)
---@field help string 此对象支持的所有方法和属性。
---@field localised_description table (只读)
---@field localised_name table (只读)
---@field locked boolean (只读) 玩家是否可以将装备移入或移出此装备栏。
---@field name string (只读) 此原型的名称。
---@field order string (只读) 此原型的排序字符串（order）。
---@field valid boolean (只读) 此对象是否有效？
---@field width integer (只读)
LuaEquipmentGridPrototype = {}

--- 模块化装备（modular equipment）的原型。
---@class LuaEquipmentPrototype
---@field background_color table (只读) 此装备原型的背景颜色。
---@field burner_prototype LuaBurnerPrototype (只读) 此装备使用的燃烧能量源原型；如果没有则为 nil。
---@field electric_energy_source_prototype LuaElectricEnergySourcePrototype (只读) 此装备使用的电力能量源原型；如果没有则为 nil。
---@field energy_consumption number (只读)
---@field energy_per_shield number (只读) 恢复每点护盾所需的能量。非护盾装备为 0。
---@field energy_production number (只读) 此装备产生的最大功率。
---@field energy_source LuaElectricEnergySourcePrototype (只读) 装备的能量源原型。
---@field equipment_categories string[] (只读) 此装备的类别名称。这些类别将用于确定此装备是否被允许放入特定装备栏。 另请参阅 LuaEquipmentGridPrototype::equipment_categories
---@field help string 此对象支持的所有方法和属性。
---@field localised_description table (只读)
---@field localised_name table (只读)
---@field logistic_parameters table (只读) 机器人港口（roboport）装备的物流参数。 包含以下字段的表： spawn_and_station_height :: float charge_approach_distance :: float logistic_radius :: float construction_radius :: float charging_station_count :: uint charging_distance :: float charging_station_shift :: Vector charging_energy :: double charging_threshold_distance :: float robot_vertical_acceleration :: float stationing_offset :: Vector robot_limit :: uint logistics_connection_distance :: float
---@field movement_bonus number (只读) 仅当这是移动加成装备原型（MovementBonusEquipmentPrototype）时可用。
---@field name string (只读) 此原型的名称。
---@field night_vision_tint table (只读) 仅当这是夜视装备原型（NightVisionEquipmentPrototype）时可用。
---@field order string (只读) 此原型的排序字符串（order）。
---@field shape table (只读) 此装备原型的形状。它是一个表： width :: uint height :: uint
---@field shield number (只读) 此装备的护盾值。非护盾装备为 0。
---@field take_result LuaItemPrototype (只读) 将此装备从装备栏中取出时得到的结果物品。如果没有结果物品则为 nil。
---@field type string (只读) 此装备原型的类型。
---@field valid boolean (只读) 此对象是否有效？
LuaEquipmentPrototype = {}

--- 封装游戏不同部分的统计数据。在流量统计（flow statistics）的语境中，input 和 output 描述数值显示在关联 GUI 的哪一侧：输入值显示在左侧，输出值显示在右侧。
---@class LuaFlowStatistics
---@field force LuaForce (只读) 这些统计所属的势力；对于污染统计则为 nil。
---@field help string 此对象支持的所有方法和属性。
---@field input_counts table<string, integer | number[]> (只读) 按名称索引的输入计数列表。 表示给定统计在 GUI 左侧显示的数据。
---@field output_counts table<string, integer | number[]> (只读) 按名称索引的输出计数列表。 表示给定统计在 GUI 右侧显示的数据。
---@field valid boolean (只读) 此对象是否有效？
LuaFlowStatistics = {}

--- 获取给定时间帧的流量计数值。
--- 参数
--- 包含以下字段的表：
--- name :: string：原型名称。
--- input :: boolean：读取输入值还是输出值。
--- precision_index :: defines.flow_precision_index：要读取的精度。
--- count :: boolean（可选）：如果为 true，返回计数而不是每时间帧的值。
---@return number count
---@param name string? name :: string：原型名称。
input :: boolean：读取输入值还是输出值。
precision_index :: defines.flow_precision_index：要读取的精度。
count :: boolean（可选）：若为 true，则返回计数而不是每时间帧的值。
function LuaFlowStatistics:get_flow_count(name) end

--- 获取给定原型的输入总数。
--- 参数
--- string：原型名称。
---@return integer | number result
---@param _string string 原型名称。
function LuaFlowStatistics:get_input_count(_string) end

--- 获取给定原型的输出总数。
--- 参数
--- string：原型名称。
---@return integer | number result
---@param _string string 原型名称。
function LuaFlowStatistics:get_output_count(_string) end

--- 向此流量统计添加一个值。
--- 参数
--- string：原型名称。
--- count :: float：数量：正数或负数决定该值进入输入统计还是输出统计。
---@param count number 数量：正负决定该值计入输入还是输出统计。
---@param _string string 原型名称。
function LuaFlowStatistics:on_flow(count, _string) end

--- 设置给定原型的输入总数。
--- 参数
--- string：原型名称。
--- count :: uint64 或 double：新数量。类型取决于统计的实例。
---@param count integer | number 新的数量。类型取决于统计实例。
---@param _string string 原型名称。
function LuaFlowStatistics:set_input_count(count, _string) end

--- 设置给定原型的输出总数。
--- 参数
--- string：原型名称。
--- count :: uint64 或 double：新数量。类型取决于统计的实例。
---@param count integer | number 新的数量。类型取决于统计实例。
---@param _string string 原型名称。
function LuaFlowStatistics:set_output_count(count, _string) end

--- 一个实体的流体箱数组。实体可能包含多个流体箱，有些实体可以改变流体箱的数量——例如，组装机将根据其当前配方改变流体箱的数量。
---@class LuaFluidBox
---@field help string 此对象支持的所有方法和属性。
---@field _operator___ table | nil? (只读) 访问、设置或清空一个流体箱。索引必须始终在边界内（参见 LuaFluidBox::operator #）。 不能使用此运算符添加或移除新的流体箱。如果给定的流体箱不包含流体，则返回 nil 。同样地，向流体箱写入 nil 可以清空其中的所有流体。
---@field _operator__ integer (只读) 流体箱的数量。
---@field owner LuaEntity (只读) 拥有此流体箱的实体。
---@field valid boolean (只读) 此对象是否有效？
LuaFluidBox = {}

--- 指定流体箱索引的容量。
--- 参数
--- index :: uint
---@return number count
---@param index integer
function LuaFluidBox:get_capacity(index) end

--- 指定流体箱索引的流体箱连接。
--- 参数
--- index :: uint
---@return LuaFluidBox[] fluidBox
---@param index integer
function LuaFluidBox:get_connections(index) end

--- 指定流体箱索引的过滤器，若无则为 'nil'。
--- 参数
--- index :: uint
--- 返回值
--- name :: string: 被过滤流体的流体原型名称。
--- minimum_temperature :: double: 允许进入流体箱的最低温度。
--- maximum_temperature :: double: 允许进入流体箱的最高温度。
--- 或 'nil'。
---@return table result
---@param index integer
function LuaFluidBox:get_filter(index) end

--- 上一 tick 中通过流体箱的流量。它是流入量和流出量中的较大值。
--- 注意，货运车厢不追踪该值，将返回 0。
--- 参数
--- index :: uint
---@return number count
---@param index integer
function LuaFluidBox:get_flow(index) end

--- 返回流体箱锁定到的流体（连同其整个系统）。
--- 若未锁定则返回 'nil'。
--- 参数
--- index :: uint
---@return string result
---@param index integer
function LuaFluidBox:get_locked_fluid(index) end

--- 此流体箱索引的原型。
--- 参数
--- index :: uint
---@return LuaFluidBoxPrototype fluidBoxPrototype
---@param index integer
function LuaFluidBox:get_prototype(index) end

--- 设置指定流体箱索引的过滤器，传 'nil' 以清除。
--- 某些实体无法设置其流体箱过滤器，尤其是流体车厢和制造机。
--- 参数
--- index :: uint
--- table: 包含以下字段的表：
--- name :: string: 被过滤流体的流体原型名称。
--- minimum_temperature :: double (可选): 允许进入流体箱的最低温度。
--- maximum_temperature :: double (可选): 允许进入流体箱的最高温度。
--- force :: boolean (可选): 无论当前流体内容如何，都强制设置过滤器。
--- 或 'nil'。
--- 返回值
--- 过滤器是否设置成功。
---@return boolean ok
---@param index integer
---@param _table string? 包含以下字段的表：
name :: string：被过滤流体的流体原型名称。
minimum_temperature :: double（可选）：允许进入流体箱的最低温度。
maximum_temperature :: double（可选）：允许进入流体箱的最高温度。
force :: boolean（可选）：强制设置过滤器，无论当前流体内容如何。
或 'nil'。
function LuaFluidBox:set_filter(index, _table) end

--- 由某个 LuaEntityPrototype 拥有的流体箱原型。
---@class LuaFluidBoxPrototype
---@field base_area number (只读)
---@field base_level number (只读)
---@field entity LuaEntityPrototype (只读) 此原型所属的实体。
---@field filter LuaFluidPrototype (只读) 过滤器，若未设置过滤器则为 nil 。
---@field height number (只读)
---@field help string 此对象支持的所有方法和属性。
---@field index integer (只读) 此流体箱原型在所属实体中的索引。
---@field maximum_temperature number (只读) 最高温度，若未设置则为 nil 。
---@field minimum_temperature number (只读) 最低温度，若未设置则为 nil 。
---@field pipe_connections table[] (只读) 管道连接点。
---@field production_type string (只读) 生产类型。"input"、"output"、"input-output" 或 "none"。
---@field render_layer string (只读) 渲染层。
---@field secondary_draw_orders integer[] (只读) 4 个可能的连接方向的次级绘制顺序。
---@field valid boolean (只读) 此对象是否有效？
---@field volume number (只读)
LuaFluidBoxPrototype = {}

--- 流体原型。
---@class LuaFluidPrototype
---@field base_color table (只读)
---@field default_temperature number (只读) 流体的默认温度。
---@field emissions_multiplier number (只读)
---@field flow_color table (只读)
---@field fuel_value number (只读)
---@field gas_temperature number (只读)
---@field group LuaGroup (只读) 此原型的组。
---@field heat_capacity number (只读) 假设蒸汽机效率为 100% 时，流体在最高温度下能产生的能量。
---@field help string 此对象支持的所有方法和属性。
---@field hidden boolean (只读)
---@field localised_description table (只读)
---@field localised_name table (只读)
---@field max_temperature number (只读) 流体能达到的最高温度。
---@field name string (只读) 此原型的名称。
---@field order string (只读) 此原型的排序字符串。
---@field subgroup LuaGroup (只读) 此原型的子组。
---@field valid boolean (只读) 此对象是否有效？
LuaFluidPrototype = {}

--- LuaForce 封装了游戏中每个"势力"（force 或 faction）的本地数据。
--- 默认势力为 player（玩家）、enemy（敌人）和 neutral（中立）。玩家和模组可以创建
--- 额外的势力（总数最多 64 个）。
---@class LuaForce
---@field ai_controllable boolean 为此势力启用一些更高级的 AI 行为。当设置为 true 时，属于此势力的虫群会自动扩张到新领土、建造新的巢穴并形成虫群单位组。默认情况下，敌人势力此值为 true ，其他势力为 false 。 注意： 将此设置为 false 并不会关闭虫群的 AI。它们仍会四处移动并攻击靠近的玩家。 注意： 势力必须可被 AI 控制，才能通过脚本创建单位组或建造基地。
---@field artillery_range_modifier number
---@field auto_character_trash_slots boolean 如果启用了自动角色丢弃槽则为 true 。角色丢弃槽还必须 &gt; 0，此功能才会实际生效。
---@field character_build_distance_bonus integer
---@field character_health_bonus number
---@field character_inventory_slots_bonus integer 角色主物品栏拥有的额外物品栏槽数量。
---@field character_item_drop_distance_bonus integer
---@field character_item_pickup_distance_bonus number
---@field character_logistic_slot_count number 角色物流槽的数量。
---@field character_loot_pickup_distance_bonus number
---@field character_reach_distance_bonus integer
---@field character_resource_reach_distance_bonus number
---@field character_running_speed_modifier number
---@field character_trash_slot_count number 角色丢弃槽的数量。
---@field connected_players LuaPlayer[] (只读) 属于此势力的已连接玩家。 当你想对此势力的所有在线玩家执行某些操作时，这尤其有用。 注意： 这里不使用玩家索引作为下标。请查看每个玩家实例的 LuaPlayer::index 以获取玩家索引。
---@field current_research LuaTechnology (只读) 当前正在研究的科技；若当前没有正在进行的研究则为 nil 。
---@field deconstruction_time_to_live integer 拆除命令被移除前的存活时间（以 tick 计）。
---@field entity_build_count_statistics LuaFlowStatistics (只读) 此势力的实体建造统计（建造和开采）。
---@field evolution_factor number 此势力的进化因子。
---@field evolution_factor_by_killing_spawners number
---@field evolution_factor_by_pollution number
---@field evolution_factor_by_time number
---@field fluid_production_statistics LuaFlowStatistics (只读) 此势力的流体生产统计。
---@field following_robots_lifetime_modifier number 跟随机器人的额外寿命。
---@field friendly_fire boolean 此势力是否启用了友军火力。
---@field ghost_time_to_live integer 放置的虚影消失前的存活时间（以 tick 计）。
---@field help string 此对象支持的所有方法和属性。
---@field index integer (只读) 与此势力关联的唯一 ID。
---@field inserter_stack_size_bonus number 非堆叠机械臂的机械臂堆叠尺寸加成。
---@field item_production_statistics LuaFlowStatistics (只读) 此势力的物品生产统计。
---@field items_launched table<string, integer> (只读) 所有已随火箭发射的物品。
---@field kill_count_statistics LuaFlowStatistics (只读) 此势力的击杀计数统计。
---@field laboratory_productivity_bonus number
---@field laboratory_speed_modifier number
---@field logistic_networks table<string, LuaLogisticNetwork[]> (只读) 按地表分组的物流网络列表。
---@field manual_crafting_speed_modifier number 手动制作速度的倍率。默认值为 0。 实际制作速度将乘以 1 + manual_crafting_speed_modifier 。 示例 将玩家的制作速度加倍 game.player.force.manual_crafting_speed_modifier = 1
---@field manual_mining_speed_modifier number 手动开采速度的倍率。默认值为 0。 实际开采速度将乘以 1 + manual_mining_speed_modifier 。 示例 将玩家的开采速度加倍 game.player.force.manual_mining_speed_modifier = 1
---@field max_failed_attempts_per_tick_per_construction_queue integer
---@field max_successful_attempts_per_tick_per_construction_queue integer
---@field maximum_following_robot_count integer 跟随机器人的最大数量。
---@field mining_drill_productivity_bonus number
---@field name string (只读) 势力的名称。 示例 打印 " player" game.player.print(game.player.force.name)
---@field players LuaPlayer[] (只读) 属于此势力的玩家。
---@field previous_research LuaTechnology 之前的科技研究（若有）。
---@field recipes table<string, LuaRecipe> (只读) 此势力可用的配方，按其名称索引。 示例 打印给定配方的类别 game.player.print(game.player.force.recipes["transport-belt"].category)
---@field research_progress number 当前研究的进度，范围为 [0, 1] 的数值。
---@field research_queue table[] 此势力的研究队列。 读取此属性会得到一个 LuaTechnology 数组。 写入此属性时，必须写入整个表。提供空表或 nil 将清空研究队列并取消当前研究。 当研究队列被禁用时写入此属性，只会将表中的最后一个研究设置为当前研究。 注意： 队列中的第一个研究即为当前研究。
---@field research_queue_enabled boolean 此势力是否可使用研究队列。
---@field rockets_launched integer 已发射的火箭数量。
---@field share_chart boolean 此势力是否启用了共享探索数据。
---@field stack_inserter_capacity_bonus integer 堆叠机械臂可转移的物品数量。写入此值时，必须 0 &gt;= 且 &lt;= 200。
---@field technologies table<string, LuaTechnology> (只读) 此势力拥有的科技，按其名称索引。 示例 为玩家的势力研究该科技 game.player.force.technologies["steel-processing"].researched = true
---@field train_braking_force_bonus number
---@field valid boolean (只读) 此对象是否有效？
---@field worker_robots_battery_modifier number
---@field worker_robots_speed_modifier number
---@field worker_robots_storage_bonus number
---@field zoom_to_world_blueprint_enabled boolean 使用 zoom-to-world（缩放至世界）时，能够使用空白蓝图物品创建新蓝图。
---@field zoom_to_world_deconstruction_planner_enabled boolean 使用 zoom-to-world 时，能够使用拆除规划器。
---@field zoom_to_world_enabled boolean 能够在地图上使用 zoom-to-world。
---@field zoom_to_world_ghost_building_enabled boolean 使用 zoom-to-world 时，能够通过蓝图或直接放置虚影来建造虚影，或"开采"虚影。
---@field zoom_to_world_selection_tool_enabled boolean 使用 zoom-to-world 时，能够使用自定义选择工具。
LuaForce = {}

--- 向指定地表添加一个自定义地图标签，并返回新标签；如果给定位置不适合放置地图标签则返回
--- nil
--- 。
--- 参数
--- surface :: SurfaceSpecification: 要添加标签的地表。
--- tag: 包含以下字段的表：
--- icon :: SignalID (可选): )
--- position :: Position
--- text :: string (可选)
--- last_user :: PlayerSpecification (可选)
--- 注意： 标签要在该位置有效，该区块必须已被探索（charted）。
--- 注意： 必须提供 icon、text 或两者之一。
---@return LuaCustomChartTag customChartTag
---@param surface table 要将标签添加到的地表。
---@param tag table? 包含以下字段的表：
icon :: SignalID（可选）
position :: Position
text :: string（可选）
last_user :: PlayerSpecification（可选）
function LuaForce:add_chart_tag(surface, tag) end

--- 如果研究队列已启用，将此科技添加到研究队列末尾。
--- 否则，将此科技设置为当前研究。
--- 参数
--- technology :: TechnologySpecification
---@param technology table
function LuaForce:add_research(technology) end

--- 取消指定地表（或所有地表）的待处理探索请求。
--- 参数
--- surface :: SurfaceSpecification (可选)
---@param surface table?
function LuaForce:cancel_charting(surface) end

--- 停止当前正在进行的研究。
--- 这将从研究队列中移除任何依赖的科技。
function LuaForce:cancel_current_research(...) end

--- 探索地图的一部分。给定区域的探索数据会被刷新；同时会为给定区域内尚未探索的部分生成探索数据。
--- 参数
--- surface :: SurfaceSpecification
--- area :: BoundingBox: 要在指定地表上探索的区域。
--- 示例
--- 探索以原点为中心、大小为 2048x2048 的矩形区域。
--- game.player.force.chart(game.player.surface,
--- {{x = -1024, y = -1024}, {x = 1024, y = 1024}})
---@param area table 在给定地表上要绘制地图的区域。
---@param surface table
function LuaForce:chart(area, surface) end

--- 探索所有已生成的区块。
--- 参数
--- surface :: SurfaceSpecification (可选): 要探索哪个地表，未给出则探索所有地表。
---@param surface table? 要绘制地图的地表；若未给出则为全部地表。
function LuaForce:chart_all(surface) end

--- 清除此势力的探索数据。
--- 参数
--- surface :: SurfaceSpecification (可选): 要清除哪个地表的探索数据；若未提供，则清除所有地表的探索数据。
---@param surface table? 要清除哪张地表的绘制数据；若未提供则清除所有地表的地图数据。
function LuaForce:clear_chart(surface) end

--- 禁用所有配方和科技。从此刻起，只有被显式启用的配方和科技才可使用。
function LuaForce:disable_all_prototypes(...) end

--- 为此势力禁用研究。
function LuaForce:disable_research(...) end

--- 启用所有配方和科技。
--- 与 LuaForce::disable_all_prototypes 相反。
function LuaForce:enable_all_prototypes(...) end

--- 解锁所有配方。
function LuaForce:enable_all_recipes(...) end

--- 解锁所有科技。
function LuaForce:enable_all_technologies(...) end

--- 为此势力启用研究。
function LuaForce:enable_research(...) end

--- 查找指定地表上、指定包围盒内的所有自定义地图标签。
--- 参数
--- surface :: SurfaceSpecification
--- area :: BoundingBox (可选)
---@return LuaCustomChartTag[] customChartTag
---@param area table?
---@param surface table
function LuaForce:find_chart_tags(area, surface) end

--- 参数
--- position :: Position: 要查找网络的位置。
--- surface :: SurfaceSpecification: 要搜索的地表。
--- 返回值
--- 找到的网络，或
--- nil
--- 。
---@return LuaLogisticNetwork result
---@param position table 要为其查找网络的位置
---@param surface table 要在其上搜索的地表
function LuaForce:find_logistic_network_by_position(position, surface) end

--- 参数
--- ammo :: string: 弹药类别。
---@return number count
---@param ammo string 弹药类别
function LuaForce:get_ammo_damage_modifier(ammo) end

--- 此势力是否会攻击另一个势力的成员？
--- 参数
--- other :: ForceSpecification
---@return boolean ok
---@param other table
function LuaForce:get_cease_fire(other) end

--- 统计指定类型的实体数量。
--- 参数
--- name :: string: 实体的原型名称。
--- 返回值
--- 属于此势力的、指定原型的实体数量。
--- 注意： 此函数的时间复杂度为 O(1)，因为实体数量由游戏引擎维护。
---@return integer count
---@param name string 实体的原型名称。
function LuaForce:get_entity_count(name) end

--- 此势力是否为友军？
--- 参数
--- other :: ForceSpecification
---@return boolean ok
---@param other table
function LuaForce:get_friend(other) end

--- 参数
--- ammo :: string: 弹药类别。
---@return number count
---@param ammo string 弹药类别
function LuaForce:get_gun_speed_modifier(ammo) end

--- 获取给定的配方是否被显式禁用手工制作。
--- 参数
--- recipe :: string 或 LuaRecipe
---@return boolean ok
---@param recipe string | LuaRecipe
function LuaForce:get_hand_crafting_disabled_for_recipe(recipe) end

--- 获取指定物品随火箭发射的数量。
--- 参数
--- item :: string: 要获取的物品。
--- 返回值
--- 该物品已发射的数量。
---@return integer count
---@param item string 要获取的物品
function LuaForce:get_item_launched(item) end

--- 获取给定科技的已保存进度；若没有已保存的进度则为
--- nil
--- 。
--- 参数
--- technology :: TechnologySpecification: 该科技。
--- 返回值
--- 以百分比表示的进度。
---@return number count
---@param technology table 科技
function LuaForce:get_saved_technology_progress(technology) end

--- 参数
--- surface :: SurfaceSpecification
---@return table result
---@param surface table
function LuaForce:get_spawn_position(surface) end

--- 获取与给定过滤器匹配的火车站。
--- 参数
--- opts (可选): 包含以下字段的表：
--- name :: string 或 string 数组 (可选)
--- surface :: SurfaceSpecification (可选)
---@return LuaEntity[] entity
---@param opts string | string[]? 包含以下字段的表：
name :: string 或 string 数组（可选）
surface :: SurfaceSpecification（可选）
function LuaForce:get_train_stops(opts) end

--- 参数
--- surface :: SurfaceSpecification (可选): 如果给出，则只返回该地表上的列车。
---@return LuaTrain[] train
---@param surface table? 若给出，则仅返回该地表上的列车。
function LuaForce:get_trains(surface) end

--- 参数
--- turret :: string: 炮塔原型名称。
---@return number count
---@param turret string 炮塔原型名称
function LuaForce:get_turret_attack_modifier(turret) end

--- 区块是否已被探索？
--- 参数
--- surface :: SurfaceSpecification
--- position :: ChunkPosition: 区块的位置。
---@return boolean ok
---@param position table 区块的位置。
---@param surface table
function LuaForce:is_chunk_charted(position, surface) end

--- 给定的区块当前是否已在地图上被探索并可见（未被战争迷雾覆盖）？
--- 参数
--- surface :: SurfaceSpecification
--- position :: ChunkPosition
---@return boolean ok
---@param position table
---@param surface table
function LuaForce:is_chunk_visible(position, surface) end

--- 寻路器是否繁忙？当寻路器繁忙时，它不会再接受任何寻路请求。
---@return boolean ok
function LuaForce:is_pathfinder_busy(...) end

--- 杀死所有单位并清空寻路器。
function LuaForce:kill_all_units(...) end

--- 为此势力的每个玩家播放一个声音。
--- 参数
--- 包含以下字段的表：
--- path :: SoundPath: 要播放的声音。
--- position :: Position (可选): 声音应在何处播放。若未给出，则在"任何地方"播放。
--- volume_modifier :: double (可选): 必须介于 0 和 1 之间（含端点）。
---@return boolean ok
---@param path table? path :: SoundPath：要播放的声音
position :: Position（可选）：声音播放的位置。若未给出，则在"所有地方"播放。
volume_modifier :: double（可选）：必须介于 0 到 1 之间（含两端）。
function LuaForce:play_sound(path) end

--- 向此势力所有玩家的聊天控制台打印文本。
--- 参数
--- message :: LocalisedString
--- color :: Color (可选)
---@param color table?
---@param message table
function LuaForce:print(color, message) end

--- 强制重新探索整个地图。
function LuaForce:rechart(...) end

--- 研究所有科技。
--- 参数
--- include_disabled_prototypes (可选): 是否也研究在原型中被显式禁用的科技。默认为 false。
---@param include_disabled_prototypes table? 是否也研究在原型中明确禁用的科技。默认为 false。
function LuaForce:research_all_technologies(include_disabled_prototypes) end

--- 重置一切。所有科技被设置为未研究状态，所有修正值被设置为默认值。
function LuaForce:reset(...) end

--- 将此势力的进化因子重置为零。
function LuaForce:reset_evolution(...) end

--- 从原型重新加载所有配方的原始版本。
function LuaForce:reset_recipes(...) end

--- 从原型重新加载科技的原始版本。保留科技的研究状态。
function LuaForce:reset_technologies(...) end

--- 重新应用所有可能的研究效果，包括已解锁的配方。任何自定义更改都将丢失。保留科技的研究状态。
function LuaForce:reset_technology_effects(...) end

--- 参数
--- ammo :: string: 弹药类别。
--- modifier :: double
---@param ammo string 弹药类别
---@param modifier number
function LuaForce:set_ammo_damage_modifier(ammo, modifier) end

--- 停止攻击给定势力的成员。
--- 参数
--- other :: ForceSpecification
--- cease_fire :: boolean: 当为
--- true
--- 时，此势力不会攻击
--- other
--- ；否则会攻击。
---@param cease_fire boolean 当为 `true` 时，此势力不会攻击 `other`；否则会攻击。
---@param other table
function LuaForce:set_cease_fire(cease_fire, other) end

--- 友军可以无限制地使用建筑，且炮塔不会攻击他们。
--- 参数
--- other :: ForceSpecification
--- cease_fire :: boolean
---@param cease_fire boolean
---@param other table
function LuaForce:set_friend(cease_fire, other) end

--- 参数
--- ammo :: string: 弹药类别。
--- modifier :: double
---@param ammo string 弹药类别
---@param modifier number
function LuaForce:set_gun_speed_modifier(ammo, modifier) end

--- 设置给定配方是否可手工制作。此方法用于显式禁用某个配方的手工制作——它不会允许手工制作原本不可手工制作的配方。
--- 参数
--- recipe :: string 或 LuaRecipe
--- hand_crafting_disabled :: boolean
---@param hand_crafting_disabled boolean
---@param recipe string | LuaRecipe
function LuaForce:set_hand_crafting_disabled_for_recipe(hand_crafting_disabled, recipe) end

--- 设置指定物品随火箭发射的数量。
--- 参数
--- item :: string: 要设置的物品。
--- count :: uint: 要设置的数量。
---@param count integer 要设置的数量
---@param item string 要设置的物品
function LuaForce:set_item_launched(count, item) end

--- 设置给定科技的已保存进度。
--- 该科技必须未在进行中、未完成，且新进度必须 &lt; 100。
--- 参数
--- technology :: TechnologySpecification: 该科技。
--- double: 以百分比表示的进度。设置为
--- nil
--- 以移除已保存的进度。
---@param _double number 以百分比表示的进度。设为 `nil` 以移除已保存的进度。
---@param technology table 科技
function LuaForce:set_saved_technology_progress(_double, technology) end

--- 参数
--- position :: Position: 指定地表上的新位置。
--- surface :: SurfaceSpecification: 要设置出生位置的地表。
---@param position table 在给定地表上的新位置。
---@param surface table 要为其设置出生点的地表。
function LuaForce:set_spawn_position(position, surface) end

--- 参数
--- turret :: string: 炮塔原型名称。
--- modifier :: double
---@param modifier number
---@param turret string 炮塔原型名称
function LuaForce:set_turret_attack_modifier(modifier, turret) end

--- 参数
--- position :: ChunkPosition: 要取消探索的区块位置。
--- surface :: SurfaceSpecification: 要取消探索的地表。
---@param position table 要取消绘制地图的区块位置。
---@param surface table 要在其上取消绘制地图的地表。
function LuaForce:unchart_chunk(position, surface) end

--- 主要的顶层类型，通过其成员提供对大部分 API 的访问。LuaGameScript 的一个实例以名为 game 的全局对象形式提供。
---@class LuaGameScript
---@field active_mods table<string, string> (只读) 当前启用的模组版本。键是模组名称，值是版本号。 示例 这将把已启用模组的名称和版本打印到玩家 p 的控制台 for name, version in pairs(game.active_mods) do p.print(name .. " version " .. version) end
---@field ammo_category_prototypes table<string, LuaAmmoCategoryPrototype> (只读)
---@field autoplace_control_prototypes table<string, LuaAutoplaceControlPrototype> (只读)
---@field autosave_enabled boolean 默认为 true。可用于禁用自动保存。 请确保之后尽快将其重新打开。
---@field backer_names table<integer, string> (只读)
---@field connected_players LuaPlayer[] (只读) 在线玩家。 当你想对所有在线玩家执行某些操作时，这尤其有用。 注意： 这里不使用玩家索引作为下标。请查看每个玩家实例的 LuaPlayer::index 以获取玩家索引。
---@field custom_input_prototypes table<string, LuaCustomInputPrototype> (只读)
---@field damage_prototypes table<string, LuaDamagePrototype> (只读)
---@field decorative_prototypes table<string, LuaDecorativePrototype> (只读)
---@field default_map_gen_settings table (只读) 此存档的默认地图生成设置。
---@field difficulty defines.difficulty (只读) 当前场景难度。
---@field difficulty_settings table (只读) 虽然可以这样做；但由于不同难度可能拥有不同的科技或配方树，不建议在游戏中途更改难度设置。
---@field draw_resource_selection boolean 默认为 true。可用于禁用资源矿脉在地图上被悬停时的高亮显示。
---@field enemy_has_vision_on_land_mines boolean 决定敌人的地雷是否完全不可见。
---@field entity_prototypes table<string, LuaEntityPrototype> (只读)
---@field equipment_grid_prototypes table<string, LuaEquipmentGridPrototype> (只读)
---@field equipment_prototypes table<string, LuaEquipmentPrototype> (只读)
---@field finished boolean (只读) 场景是否已结束。
---@field fluid_prototypes table<string, LuaFluidPrototype> (只读)
---@field forces table<string, LuaForce> (只读)
---@field item_prototypes table<string, LuaItemPrototype> (只读)
---@field map_settings table (只读)
---@field mod_setting_prototypes table<string, LuaModSettingPrototype> (只读)
---@field named_noise_expressions table<string, LuaNamedNoiseExpression> (只读)
---@field noise_layer_prototypes table<string, LuaNoiseLayerPrototype> (只读)
---@field permissions LuaPermissionGroups (只读)
---@field player LuaPlayer (只读) 在控制台输入命令的玩家——在所有其他情况下为 nil 。参见 LuaGameScript::players 以访问所有玩家。
---@field players table<integer | string, LuaPlayer> (只读) 注意： 这是一个稀疏表，因此应使用 pairs()、已知的玩家索引或玩家名称来访问元素。
---@field pollution_statistics LuaFlowStatistics (只读) 此地图的污染统计。
---@field recipe_prototypes table<string, LuaRecipePrototype> (只读)
---@field speed number 地图更新的速度。1.0 为正常速度——60 UPS。 注意： 最小值为 0.01。
---@field styles table<string, string> (只读) LuaGuiElement 可使用的样式。
---@field surfaces table<integer | string, LuaSurface> (只读)
---@field technology_prototypes table<string, LuaTechnologyPrototype> (只读)
---@field tick integer (只读) 当前地图 tick。
---@field tick_paused boolean tick 是否已暂停。这意味着实体更新已被暂停。
---@field ticks_played integer (只读) 自该游戏被"创建"以来经过的 tick 数。 游戏通过使用"new game"（新游戏）或"new game from scenario"（从场景新建游戏）来"创建"。 注意： 这与 LuaGameScript::tick 不同：从场景新建游戏时，即使场景拥有自己的关卡数据（其 LuaGameScript::tick &gt; 0），ticks_played 也始终从 0 开始。 注意： 此值与 LuaGameScript::tick 没有关系，可以完全不同。
---@field ticks_to_run integer tick 暂停期间要运行的 tick 数。 当 LuaGameScript::tick_paused 为 true 时，ticks_to_run 的行为如下： 当此值 &gt; 0 时，实体更新正常进行，且此值每个 tick 递减 1。当此值达到 0 时，游戏将再次暂停。
---@field tile_prototypes table<string, LuaTilePrototype> (只读)
---@field virtual_signal_prototypes table<string, LuaVirtualSignalPrototype> (只读)
LuaGameScript = {}

--- 指示游戏执行一次自动保存。
--- 参数
--- name :: string (可选): 自动保存的名称（若有）。提供时，存档将被命名为 _autosave-name。
--- 注意： 在多人游戏中只有服务器会保存。在单人游戏中会触发一次标准的自动保存。
---@param name string? 自动存档名称（若有）。提供时存档将命名为 _autosave-*name*。
function LuaGameScript:auto_save(name) end

--- 将给定玩家从该多人游戏中封禁。如果这是单人游戏，或者执行此操作的玩家不是管理员，则不做任何事。
--- 参数
--- PlayerSpecification: 要封禁的玩家。
--- reason :: LocalisedString (可选): 给出的原因（若有）。
---@param PlayerSpecification table 要封禁的玩家。
---@param reason table? 给出的原因（若有）。
function LuaGameScript:ban_player(PlayerSpecification, reason) end

--- 运行内部一致性检查。据说会打印它发现的任何错误。
--- 注意： 主要用于调试目的。
function LuaGameScript:check_consistency(...) end

--- 遍历所有物品、实体、地块、配方、科技等内容，并记录区域设置（locale）是否正确。
--- 注意： 若从控制台调用，还会打印 true/false。
function LuaGameScript:check_prototype_translations(...) end

--- 统计世界中存在多少个不同的管道组。
function LuaGameScript:count_pipe_groups(...) end

--- 创建一个新势力。
--- 参数
--- force :: string: 新势力的名称。
--- 返回值
--- 刚刚创建的势力。
--- 注意： 游戏当前最多支持 64 个势力，包括三个内置势力。
--- 这意味着最多只能创建 61 个新势力。
--- 注意： 势力名称必须唯一。
---@return LuaForce result
---@param force string 新势力的名称
function LuaGameScript:create_force(force) end

--- 创建一个 LuaProfiler，用于测量脚本性能。
--- 注意： LuaProfiler 无法被序列化。
---@return LuaProfiler profiler
function LuaGameScript:create_profiler(...) end

--- 使用给定的种子创建一个确定性的独立随机生成器；若未提供种子，则使用初始地图种子。
--- 参数
--- seed :: uint (可选)
--- 注意： 请确保你确实想用它而不是 math.random(...)，因为它提供了与 math.random(...) 完全不同的功能。
---@return LuaRandomGenerator result
---@param seed integer?
function LuaGameScript:create_random_generator(seed) end

--- 创建一个新地表。
--- 参数
--- name :: string: 新地表的名称。
--- settings :: MapGenSettings (可选): 地图生成设置。
--- 返回值
--- 刚刚创建的地表。
--- 注意： 游戏当前最多支持 4,294,967,295 个地表，包括默认地表。
--- 注意： 地表名称必须唯一。
---@return LuaSurface surface
---@param name string 新地表的名称
---@param settings table? 地图生成设置
function LuaGameScript:create_surface(name, settings) end

--- 删除给定的地表及其上的所有实体。
--- 参数
--- surface :: string 或 LuaSurface: 要删除的地表。目前主地表（1, 'nauvis'）无法被删除。
---@param surface string | LuaSurface 要删除的地表。目前主地表 (1, 'nauvis') 无法删除。
function LuaGameScript:delete_surface(surface) end

--- 将给定的方向转换为该方向的字符串版本。
--- 参数
--- direction :: defines.direction
---@param direction defines.direction
function LuaGameScript:direction_to_string(direction) end

--- 为当前存档文件禁用回放保存。一旦完成，除非加载旧存档，否则无法为存档文件重新启用回放保存。
function LuaGameScript:disable_replay(...) end

--- 禁用提示与技巧的显示。
function LuaGameScript:disable_tips_and_tricks(...) end

--- 禁用教程触发器，这些触发器用于解锁新教程并显示关于已解锁教程的通知。
function LuaGameScript:disable_tutorial_triggers(...) end

--- 强制进行 CRC 检查。要求所有对等端计算当前地图 CRC；然后这些 CRC 会相互比较。如果检测到不匹配，游戏将失去同步，某些对等端会被强制重新连接。
function LuaGameScript:force_crc(...) end

--- 获取活跃（每 tick 更新）实体的数量。
--- 参数
--- surface :: SurfaceSpecification (可选): 如果给出，则只统计该地表上活跃的实体。
--- 注意： 计算此值非常昂贵。
---@return integer count
---@param surface table? 如果指定，则只统计在该地表上活动的实体。
function LuaGameScript:get_active_entities_count(surface) end

--- 参数
--- tag :: string
---@return LuaEntity entity
---@param tag string
function LuaGameScript:get_entity_by_tag(tag) end

--- 获取用于创建此地图的地图生成设置所对应的地图交换字符串。
---@return string result
function LuaGameScript:get_map_exchange_string(...) end

--- 获取给定的玩家；若找不到该玩家则返回
--- nil
--- 。
--- 参数
--- player :: uint 或 string: 玩家索引或名称。
--- 注意： 这是 game.players[...] 的快捷方式。
---@return LuaPlayer player
---@param player integer | string 玩家的索引或名称。
function LuaGameScript:get_player(player) end

--- 获取给定的地表；若找不到该地表则返回
--- nil
--- 。
--- 参数
--- surface :: uint 或 string: 地表索引或名称。
--- 注意： 这是 game.surfaces[...] 的快捷方式。
---@return LuaSurface surface
---@param surface integer | string 地表的索引或名称。
function LuaGameScript:get_surface(surface) end

--- 获取与给定过滤器匹配的火车站。
--- 参数
--- opts (可选): 包含以下字段的表：
--- name :: string 或 string 数组 (可选)
--- surface :: SurfaceSpecification (可选)
--- force :: ForceSpecification (可选)
---@return LuaEntity[] entity
---@param opts string | string[]? 包含以下字段的表:  
name :: string 或 string 数组 (可选)  
surface :: SurfaceSpecification (可选)  
force :: ForceSpecification (可选)
function LuaGameScript:get_train_stops(opts) end

--- 内部
function LuaGameScript:help(...) end

--- 这是否是 Factorio 的演示版本。
---@return boolean ok
function LuaGameScript:is_demo(...) end

--- 加载的地图是否处于多人游戏模式。
---@return boolean ok
function LuaGameScript:is_multiplayer(...) end

--- 检查给定的声音路径是否有效。
--- 参数
---@return boolean ok
---@param undefined any
function LuaGameScript:is_valid_sound_path(undefined) end

--- 将 JSON 字符串转换为表。
--- 参数
--- json :: string: 要转换的字符串。
--- 返回值
--- 返回的对象；若 JSON 无效则为
--- nil
--- 。
---@return any result
---@param json string 要转换的字符串
function LuaGameScript:json_to_table(json) end

--- 将给定玩家从该多人游戏中踢出。如果这是单人游戏，或者执行此操作的玩家不是管理员，则不做任何事。
--- 参数
--- PlayerSpecification: 要踢出的玩家。
--- reason :: LocalisedString (可选): 给出的原因（若有）。
---@param PlayerSpecification table 要踢出的玩家。
---@param reason table? 给出的原因（若有）。
function LuaGameScript:kick_player(PlayerSpecification, reason) end

--- 将两个势力标记为合并。源势力中的所有实体将被重新分配到目标势力。
--- 然后源势力将被销毁。
--- 参数
--- source :: ForceSpecification: 要移除的势力。
--- destination :: ForceSpecification: 要将所有实体重新分配到的势力。
--- 注意： 三个内置势力——player、enemy 和 neutral——无法被销毁。也就是说，它们不能作为此函数的 source 参数。
--- 注意： 源势力直到当前 tick 结束才会被合并；
--- 若在 on_forces_merging 事件或 on_forces_merged 事件期间调用，则在下一个 tick 结束时合并。
---@param destination table 要将所有实体重新分配到的势力
---@param source table 要移除的势力
function LuaGameScript:merge_forces(destination, source) end

--- 将给定玩家静音。如果执行此操作的玩家不是管理员，则不做任何事。
--- 参数
--- PlayerSpecification: 要静音的玩家。
---@param PlayerSpecification table 要禁言的玩家。
function LuaGameScript:mute_player(PlayerSpecification) end

--- 在游戏中的每个地表上为每个玩家播放一个声音。
--- 参数
--- 包含以下字段的表：
--- path :: SoundPath: 要播放的声音。
--- position :: Position (可选): 声音应在何处播放。若未给出，则在"任何地方"播放。
--- volume_modifier :: double (可选): 必须介于 0 和 1 之间（含端点）。
---@return boolean ok
---@param path table? path :: SoundPath：要播放的声音
position :: Position（可选）：声音播放的位置。若未给出，则在"所有地方"播放。
volume_modifier :: double（可选）：必须介于 0 到 1 之间（含两端）。
function LuaGameScript:play_sound(path) end

--- 向所有玩家的聊天控制台打印文本。
--- 参数
--- message :: LocalisedString
--- color :: Color (可选)
---@param color table?
---@param message table
function LuaGameScript:print(color, message) end

--- 从游戏中清除给定玩家的消息。如果执行此操作的玩家不是管理员，则不做任何事。
--- 参数
--- PlayerSpecification: 要清除消息的玩家。
---@param PlayerSpecification table 要清除的玩家。
function LuaGameScript:purge_player(PlayerSpecification) end

--- 在所有地表上重新生成某些实体的自动放置。这可用于自动放置新添加的实体。
--- 参数
--- entities :: string 或 string 数组
--- 要自动放置的实体原型名称。
--- 注意： 所有指定的实体原型必须可自动放置。
---@param entities string | string[]
function LuaGameScript:regenerate_entity(entities) end

--- 强制重新加载所有模组。
--- 注意： 从模组的角度来看，这相当于保存并重新加载。
--- 注意： 如果在多人游戏中运行，此操作将不做任何事。
--- 注意： 如果启用了回放，此操作会禁用回放。
function LuaGameScript:reload_mods(...) end

--- 从原始场景位置强制重新加载场景脚本。
--- 注意： 如果启用了回放，此操作会禁用回放。
function LuaGameScript:reload_script(...) end

--- 从地图中移除当前未连接的玩家。
--- 参数
--- players :: LuaPlayer 或 string 数组 (可选): 要移除的玩家列表。若未指定，
--- 则移除所有离线玩家。
---@param players LuaPlayer | string[]? 要移除的玩家列表。如果未指定，则移除所有离线玩家。
function LuaGameScript:remove_offline_players(players) end

--- 移除文件或目录。给定的路径相对于脚本输出目录。可用于移除由 LuaGameScript::write_file 创建的文件。
--- 参数
--- path :: string: 要移除的路径，相对于脚本输出目录。
---@param path string 要移除的路径，相对于脚本输出目录
function LuaGameScript:remove_path(path) end

--- 将 Atlas 的当前配置保存到文件。这将产生一个巨大的文件，其中包含尽可能压缩到小空间的游戏图形。
--- 注意： 主要用于调试目的。
function LuaGameScript:save_atlas(...) end

--- 指示服务器保存地图。
--- 参数
--- name :: string (可选): 存档名称。若未指定，则写入当前正在运行的存档。
---@param name string? 存档名称。如果未指定，则写入当前正在运行的存档。
function LuaGameScript:server_save(name) end

--- 设置场景状态。
--- 参数
--- 包含以下字段的表：
--- game_finished :: boolean
--- player_won :: boolean
--- next_level :: string
--- can_continue :: boolean
--- victorious_force :: ForceSpecification
---@param game_finished boolean game_finished :: boolean  
player_won :: boolean  
next_level :: string  
can_continue :: boolean  
victorious_force :: ForceSpecification
function LuaGameScript:set_game_state(game_finished) end

--- 强制截图保存系统等待，直到所有排队的截图都已写入磁盘。
function LuaGameScript:set_wait_for_screenshots_to_finish(...) end

--- 显示一个游戏内消息对话框。
--- 参数
--- 包含以下字段的表：
--- text :: LocalisedString: 对话框应显示的内容。
--- image :: string (可选): 要在对话框上显示的图片路径。
--- point_to :: GuiArrowSpecification (可选)
--- 如果指定，对话框将显示一个指向该位置的箭头。若未指定，箭头将指向玩家的位置。
--- （使用
--- point_to={type="nowhere"}
--- 可完全移除箭头。）对话框本身将放置在箭头目标附近。
--- 注意： 仅当地图中恰好只有一个玩家时才能使用。
---@param text table? text :: LocalisedString: 对话框要显示的内容  
image :: string (可选): 要在对话框上显示的图片路径  
point_to :: GuiArrowSpecification (可选)  
如果指定，对话框将显示指向该位置的箭头。如果未指定，箭头将指向玩家的位置。  
(使用 ````
point_to={type="nowhere"}````
可完全移除箭头。) 对话框本身将放置在箭头目标附近。
function LuaGameScript:show_message_dialog(text) end

--- 将表转换为 JSON 字符串。
--- 参数
--- data :: table
---@return string result
---@param data table
function LuaGameScript:table_to_json(data) end

--- 截取屏幕截图并保存到文件。
--- 参数
--- 包含以下字段的表：
--- player :: PlayerSpecification (可选)
--- by_player :: PlayerSpecification (可选): 如果定义，则只为该玩家截图。
--- surface :: SurfaceSpecification (可选): 如果定义，则在该地表上截图。
--- position :: Position (可选): 如果定义，截图将以该位置为中心。
--- resolution :: Position (可选): 允许的最大分辨率为 16384x16384（当 anti_alias 为 true 时相应为 8192x8192），但推荐的最大分辨率为 4096x4096（相应为 2048x2048）。
--- zoom :: double (可选)
--- path :: string (可选): 保存截图的路径。
--- show_gui :: boolean (可选): 截图中是否包含游戏界面（GUI）？
--- show_entity_info :: boolean (可选): 是否包含实体信息（alt 模式）？
--- anti_alias :: boolean (可选): 是否以双倍分辨率渲染再缩小（包括 GUI）？
--- quality :: int (可选): 使用 jpg 格式时的渲染质量（0-100，含端点）。
--- 注意： 如果 Factorio 以无头（headless）模式运行，此函数将不做任何事。
---@param player table? player :: PlayerSpecification (可选)  
by_player :: PlayerSpecification (可选): 如果定义，则只为该玩家拍摄截图。  
surface :: SurfaceSpecification (可选): 如果定义，则在该地表上拍摄截图。  
position :: Position (可选): 如果定义，截图将以该位置为中心。  
resolution :: Position (可选): 允许的最大分辨率为 16384x16384（当 anti_alias 为 true 时为 8192x8192），但推荐的最大分辨率为 4096x4096（对应 2048x2048）。  
zoom :: double (可选)  
path :: string (可选): 保存截图的路径  
show_gui :: boolean (可选): 截图是否包含游戏 GUI？  
show_entity_info :: boolean (可选): 是否包含实体信息（alt-mode）？  
anti_alias :: boolean (可选): 是否以双倍分辨率渲染再缩小（包括 GUI）？  
quality :: int (可选): 使用 jpg 格式时的渲染质量（0-100 含端点）。
function LuaGameScript:take_screenshot(player) end

--- 参数
--- 包含以下字段的表：
--- force :: ForceSpecification (可选): 要使用的势力。若未给出，则使用
--- "player
--- " 势力。
--- path :: string (可选): 保存截图的路径。
--- by_player :: PlayerSpecification (可选): 如果定义，则只为该玩家截图。
--- selected_technology :: TechnologySpecification (可选): 要高亮的科技。
--- skip_disabled :: boolean (可选): 如果为
--- true
--- ，将跳过被禁用的科技。它们的后继科技
--- 将被连接到被禁用科技的父科技上。默认为
--- false
--- 。
--- quality :: int (可选): 使用 jpg 格式时的渲染质量（0-100，含端点）。
---@param force table? force :: ForceSpecification (可选): 要使用的势力。如果未给出，则使用 ````
"player````
" 势力。  
path :: string (可选): 保存截图的路径。  
by_player :: PlayerSpecification (可选): 如果定义，则只为该玩家拍摄截图。  
selected_technology :: TechnologySpecification (可选): 要高亮显示的科技。  
skip_disabled :: boolean (可选): 如果为 ````
true````
，将跳过已禁用的科技。它们的后继科技将连接到被禁用科技的父科技上。默认为 ````
false````
。  
quality :: int (可选): 使用 jpg 格式时的渲染质量（0-100 含端点）。
function LuaGameScript:take_technology_screenshot(force) end

--- 解除给定玩家在该多人游戏中的封禁。如果这是单人游戏，或者执行此操作的玩家不是管理员，则不做任何事。
--- 参数
--- PlayerSpecification: 要解封的玩家。
---@param PlayerSpecification table 要解封的玩家。
function LuaGameScript:unban_player(PlayerSpecification) end

--- 取消给定玩家的静音。如果执行此操作的玩家不是管理员，则不做任何事。
--- 参数
--- PlayerSpecification: 要取消静音的玩家。
---@param PlayerSpecification table 要解除禁言的玩家。
function LuaGameScript:unmute_player(PlayerSpecification) end

--- 将字符串写入文件。
--- 参数
--- filename :: string: 要写入的文件的路径。
--- data :: LocalisedString: 文件内容。
--- append :: boolean (可选): 当为
--- true
--- 时，将追加到文件末尾。默认为
--- false
--- ，即用新数据覆盖任何已有文件。
--- for_player :: uint (可选): 如果给出，则只为该 player_index 写入文件。0 表示仅服务器（若存在）。
---@param append boolean? 为 ````
true````
时，将追加到文件末尾。默认为 ````
false````
，即用新数据覆盖任何已存在的文件。
---@param data table 文件内容
---@param filename string 要写入的文件的路径。
---@param for_player integer? 如果指定，文件将只为该 player_index 写入。0 表示仅当存在服务器时才写入服务器。
function LuaGameScript:write_file(append, data, filename, for_player) end

--- 支持根据某种条件将实体开启或关闭的行为的抽象基类。
---@class LuaGenericOnOffControlBehavior
---@field circuit_condition table 电路条件。 注意： 可将 condition 设为 nil 以清除电路条件。 示例 让实体在接收到超过 4 个铁路链式信号灯信号的电路信号时被激活（例如让灯亮起）。 a_behavior.circuit_condition = {condition={comparator=">", first_signal={type="item", name="rail-chain-signal"}, constant=4}}
---@field connect_to_logistic_network boolean 如果此行为应连接到物流网络则为 true 。
---@field disabled boolean (只读) 实体当前是否因控制行为而被禁用。
---@field entity LuaEntity (只读) 此控制行为所属的实体。
---@field help string 此对象支持的所有方法和属性。
---@field logistic_condition table 物流条件。 注意： 可将 condition 设为 nil 以清除物流条件。 示例 让实体在其连接的物流网络拥有超过 4 个铁路链式信号灯信号时被激活（例如让灯亮起）。 a_behavior.logistic_condition = {condition={comparator=">", first_signal={type="item", name="rail-chain-signal"}, constant=4}}
---@field type defines.control_behavior.type (只读) 此控制行为的具体类型。
---@field valid boolean (只读) 此对象是否有效？
LuaGenericOnOffControlBehavior = {}

--- 参数
--- wire :: defines.wire_type: 连接到该实体的网络的导线颜色。
--- circuit_connector :: defines.circuit_connector_id (可选): 要获取电路网络的连接器。
--- 对于拥有多个电路网络连接器的实体必须指定。
--- 返回值
--- 电路网络或 nil。
---@return LuaCircuitNetwork result
---@param circuit_connector defines.circuit_connector_id? 要获取其电路网络的连接器。
对于拥有多个电路网络连接器的实体，必须指定此项。
---@param wire defines.wire_type 连接到此实体的网络的导线颜色。
function LuaGenericOnOffControlBehavior:get_circuit_network(circuit_connector, wire) end

--- 物品组或子组。
---@class LuaGroup
---@field group LuaGroup (只读) 父组（若有）；若无则为 nil 。
---@field help string 此对象支持的所有方法和属性。
---@field localised_name table (只读) 组的本地化名称。
---@field name string (只读)
---@field order string (只读)
---@field order_in_recipe string (只读) 配方排序中使用的附加排序值。 注意： 只能用于组，不能用于子组。
---@field subgroups LuaGroup[] (只读) 此组的子组。 注意： 只能用于组，不能用于子组。
---@field type string (只读)
---@field valid boolean (只读) 此对象是否有效？
LuaGroup = {}

--- GUI 的根。此类型包含根元素 top、left、center 和 goal，可以向其中添加其他元素以在屏幕上显示。
---@class LuaGui
---@field center LuaGuiElement (只读) GUI 的中间部分。它是一个 flow（流式）元素。
---@field children table<string, LuaGuiElement> (只读) 子 GUI 元素，按名称 &lt;&gt; 元素 映射。
---@field goal LuaGuiElement (只读) 目标窗口中使用的 flow（流式）元素。它是一个 flow 元素。 目标窗口仅在 flow 不为空或目标文本已设置时才可见。
---@field help string 此对象支持的所有方法和属性。
---@field left LuaGuiElement (只读) GUI 的左侧部分。它是一个 flow（流式）元素。
---@field player LuaPlayer (只读) 拥有此界面的玩家。
---@field top LuaGuiElement (只读) GUI 的顶部部分。它是一个 flow（流式）元素。
---@field valid boolean (只读) 此对象是否有效？
LuaGui = {}

--- 如果 sprite_path 有效且包含已加载的精灵图，则返回
--- true
--- ，否则返回
--- false
--- 。类型为
--- file
--- 的精灵图路径不会校验文件是否存在。
--- 参数
--- sprite_path :: SpritePath: 图片的路径。
---@return boolean ok
---@param sprite_path table 图片的路径。
function LuaGui:is_valid_sprite_path(sprite_path) end

--- 自定义 GUI 的元素。此类型用于表示任何种类的 GUI 元素——标签、按钮和框架都是此类型的实例。与 LuaEntity 一样，不同种类的元素支持不同的属性；尝试访问某个元素不支持的属性（例如，尝试访问文本框的值）将导致运行时错误。
---@class LuaGuiElement
---@field caption table 显示在元素上的文本。对于框架（frame），这是"标题"；对于其他元素（如按钮和标签），这是内容。 注意： 虽然此属性可用于所有元素而不会产生错误，但对表格和流式元素没有意义，因为它们不会显示它。
---@field children LuaGuiElement[] (只读) 子元素。
---@field children_names string[] (只读) 此元素所有子元素的名称。这些是可用于将子元素作为此元素的属性来访问的标识符。
---@field clicked_sprite table 此 sprite-button 被点击时显示的图片。
---@field column_count integer (只读) 此 table 中的列数。 _仅当此元素是 table 时才可使用_
---@field direction string (只读) 布局的方向。可以是 "horizontal" 或 "vertical" 。 _仅当此元素是 frame 或 flow 时才可使用_
---@field draw_horizontal_line_after_headers boolean 此 table 是否应在表头之后绘制一条水平网格线。 _仅当此元素是 table 时才可使用_
---@field draw_horizontal_lines boolean 此 table 是否应绘制水平网格线。 _仅当此元素是 table 时才可使用_
---@field draw_vertical_lines boolean 此 table 是否应绘制垂直网格线。 _仅当此元素是 table 时才可使用_
---@field elem_type string (只读) 此 choose-elem-button 的 elem 类型。 _仅当此元素是 choose-elem-button 时才可使用_
---@field elem_value string | table 此 choose-elem-button 的 elem 值；若没有值则为 nil 。 注意： 类型 "item"、"entity" 和 "tile" 使用字符串。类型 "signal" 使用 SignalID。 _仅当此元素是 choose-elem-button 时才可使用_
---@field enabled boolean 此 GUI 元素是否启用。
---@field entity LuaEntity 与此 entity-preview 关联的实体；若未关联实体则为 nil 。 _仅当此元素是 entity-preview 时才可使用_
---@field force string 此 minimap 正在使用的势力；若未设置势力则为 nil 。
---@field gui LuaGui (只读) 此元素所属的 GUI。
---@field help string 此对象支持的所有方法和属性。
---@field horizontal_scroll_policy string 水平滚动条的策略，可选值为 "auto"（默认）、"never"、"always"、"auto-and-reserve-space"。 _仅当此元素是 scroll-pane 时才可使用_
---@field hovered_sprite table 此 sprite-button 被悬停时显示的图片。 _仅当此元素是 sprite-button 时才可使用_
---@field ignored_by_interaction boolean 此 GUI 元素是否被交互忽略。 这意味着，例如，按钮上的标签无法夺取按钮的焦点或点击事件。
---@field index integer (只读) 此 GUI 元素的唯一索引。
---@field items table[] 此 drop-down 或 list-box 中的条目。
---@field locked boolean 此 choose-elem-button 是否可被玩家更改。 _仅当此元素是 choose-elem-button 时才可使用_
---@field minimap_player_index integer 此 minimap 正在使用的玩家索引。 _仅当此元素是 minimap 时才可使用_
---@field mouse_button_filter table<string, boolean> 此 button 或 sprite-button 的鼠标按键过滤器。 可能的过滤器有： "left-and-right" "left" "right" "middle" "button-4" "button-5" "button-6" "button-7" "button-8" "button-9"
---@field name string (只读) 此元素的名称。 示例 game.player.gui.top.greeting.name == "greeting"
---@field _number number 要显示在 sprite-button 右下角的数字；设为 nil 则不显示任何内容。
---@field _operator___ LuaGuiElement (只读) 索引运算符。按名称获取子元素。
---@field parent LuaGuiElement (只读) 此元素的直接父元素；若这是顶层元素则为 nil 。
---@field player_index integer (只读) 指向 LuaGameScript::players 的索引，指定拥有此元素的玩家。
---@field position table 此 camera 或 minimap 聚焦的位置（若有）。
---@field read_only boolean 此 text-box 是否只读。 _仅当此元素是 text-box 时才可使用_
---@field resize_to_sprite boolean 图片控件是否应根据其中的精灵图调整自身大小（默认为 true）。
---@field selectable boolean 此 text-box 的内容是否可选中。 _仅当此元素是 text-box 时才可使用_
---@field selected_index integer 此 drop-down 或 list-box 的选中索引。若无则为 0。
---@field show_percent_for_small_numbers boolean 与显示在 sprite-button 右下角的数字有关。 当设置为 true 时，非 0 且小于 1 的数字将以百分比而非数值形式显示， 例如 0.5 将显示为 50%。
---@field slider_value number 此 slider 元素的值。 _仅当此元素是 slider 时才可使用_
---@field sprite table 此 sprite-button 或 sprite 在默认状态下显示的图片。
---@field state boolean 此 checkbox 是否被勾选？ _仅当此元素是 checkbox 时才可使用_
---@field style LuaStyle | string 此元素的样式。读取时，其值为一个 LuaStyle。写入时，它只接受指定所需样式文本标识符的字符串。
---@field surface_index integer 此 camera 或 minimap 正在使用的地表索引。
---@field text string textfield 或 text-box 中包含的文本。 _仅当此元素是 textfield 或 text-box 时才可使用_
---@field tooltip table
---@field type string (只读) 此 GUI 元素的类型。
---@field valid boolean (只读) 此对象是否有效？
---@field value number 此进度条的填充程度。取值范围为 [0, 1]。 _仅当此元素是 progressbar 时才可使用_
---@field vertical_centering boolean 此 table 的字段是否应垂直居中。默认为 true，并覆盖 LuaStyle::column_alignments。 _仅当此元素是 table 时才可使用_
---@field vertical_scroll_policy string 垂直滚动条的策略，可选值为 "auto"（默认）、"never"、"always"、"auto-and-reserve-space"。 _仅当此元素是 scroll-pane 时才可使用_
---@field visible boolean 当不可见时，GUI 元素被完全隐藏，且不占用布局空间。
---@field word_wrap boolean 此 text-box 是否自动换行。 _仅当此元素是 text-box 时才可使用_
---@field zoom number 此 camera 或 minimap 正在使用的缩放。
LuaGuiElement = {}

--- 添加一个子元素。
--- 参数
--- 包含以下字段的表：
--- type :: string: 要添加的元素种类。必须是
--- "button"
--- 、
--- "sprite-button"
--- "checkbox"
--- 、
--- "flow"
--- 、
--- "frame"
--- 、
--- "label"
--- 、
--- "progressbar"
--- 、
--- "table"
--- 、
--- "textfield"
--- "radiobutton"
--- 、
--- "sprite"
--- 、
--- "scroll-pane"
--- 、
--- "drop-down"
--- 、
--- "list-box"
--- 、
--- "camera"
--- "choose-elem-button"
--- 、
--- "text-box"
--- 、
--- "slider"
--- 、
--- "minimap"
--- 或
--- "entity-preview"
--- 之一。
--- name :: string: 子元素的名称。
--- caption :: LocalisedString (可选): 显示在子元素上的文本。对于框架（frame），这是"标题"；对于其他元素（如按钮和标签），这是内容。虽然此属性可用于所有元素，但对表格和流式元素没有意义，因为它们不会显示它。
--- tooltip :: LocalisedString (可选): 子元素的提示文本。
--- enabled :: boolean (可选): 子元素是否启用。
--- ignored_by_interaction :: boolean (可选): 子元素是否被交互忽略。
--- style :: string (可选): 新元素的样式。
--- 根据
--- type
--- 的不同，可能还需要指定其他属性。
--- button
--- mouse_button_filter :: MouseButtonFlags (可选): 按钮响应哪些鼠标按键。
--- flow
--- direction :: string: flow 布局的初始方向。参见 LuaGuiElement::direction。
--- frame
--- direction :: string: frame 布局的初始方向。参见 LuaGuiElement::direction。
--- table
--- column_count :: uint: 列数。
--- draw_vertical_lines :: boolean (可选): 表格是否应绘制垂直网格线。若未给出，默认为
--- false
--- 。
--- draw_horizontal_lines :: boolean (可选): 表格是否应绘制水平网格线。若未给出，默认为
--- false
--- 。
--- draw_horizontal_line_after_headers :: boolean (可选): 表格是否应在表头之后绘制一条水平网格线。若未给出，默认为
--- false
--- 。
--- vertical_centering :: boolean (可选): 此表格的字段是否应垂直居中。若未给出，默认为
--- true
--- 。
--- textfield
--- text :: string (可选): textfield 中包含的初始文本。
--- progressbar
--- value :: double (可选): progressbar 的初始值，范围为 [0, 1]。若未给出，默认为 0。
--- checkbox
--- state :: boolean: checkbox 是否应默认被勾选。
--- radiobutton
--- state :: boolean: radiobutton 是否应默认被选中。
--- sprite-button
--- sprite :: SpritePath (可选): 显示在按钮上的图片路径。
--- hovered_sprite :: SpritePath (可选): 按钮被悬停时显示的图片路径。
--- clicked_sprite :: SpritePath (可选): 按钮被点击时显示的图片路径。
--- number :: double (可选): 显示在按钮上的数字。
--- show_percent_for_small_numbers :: boolean (可选): 将小数字格式化为百分比。若未给出，默认为
--- false
--- 。
--- mouse_button_filter :: MouseButtonFlags (可选): 按钮响应哪些鼠标按键。
--- sprite
--- sprite :: SpritePath (可选): 要显示的图片路径。
--- scroll-pane
--- horizontal_scroll_policy :: string (可选): 水平滚动条的策略，可选值为 "auto"（默认）、"never"、"always"、"auto-and-reserve-space"。
--- vertical_scroll_policy :: string (可选): 垂直滚动条的策略，可选值为 "auto"（默认）、"never"、"always"、"auto-and-reserve-space"。
--- drop-down
--- items :: LocalisedString 数组 (可选): drop-down 中的初始条目。
--- selected_index :: uint (可选): 初始选中索引。
--- list-box
--- items :: LocalisedString 数组 (可选): list-box 中的初始条目。
--- selected_index :: uint (可选): 初始选中索引。
--- camera
--- position :: Position: camera 中心对准的位置。
--- surface_index :: uint (可选): camera 将渲染的地表；若未给出，则使用玩家的地表。
--- zoom :: double (可选): camera 的缩放——默认为 0.75。
--- choose-elem-button
--- elem_type :: string: "item"、"tile"、"entity"、"signal"、"fluid" 或 "recipe"。
--- item :: string (可选): 若 type 为 "item"——按钮的默认值。
--- tile :: string (可选): 若 type 为 "tile"——按钮的默认值。
--- entity :: string (可选): 若 type 为 "entity"——按钮的默认值。
--- signal :: SignalID (可选): 若 type 为 "signal"——按钮的默认值。
--- fluid :: string (可选): 若 type 为 "fluid"——按钮的默认值。
--- recipe :: string (可选): 若 type 为 "recipe"——按钮的默认值。
--- text-box
--- text :: string (可选): text-box 中包含的初始文本。
--- slider
--- minimum_value :: double (可选): slider 的最小值。
--- maximum_value :: double (可选): slider 的最大值。
--- value :: double (可选): slider 的初始值。
--- minimap
--- position :: Position (可选): minimap 中心对准的位置；若未给出，则以拥有此元素的玩家为中心。
--- surface_index :: uint (可选): camera 将渲染的地表；若未给出，则使用玩家的地表。
--- chart_player_index :: uint (可选): 地图应使用的玩家索引；若未设置，则使用拥有此元素的玩家。
--- force :: string (可选): minimap 应使用的势力；若未给出，则使用拥有此元素的玩家的势力。
--- zoom :: double (可选): camera 的缩放——默认为 0.75。
--- 返回值
--- 添加的 GUI 元素。
---@return LuaGuiElement guiElement
---@param type string? type :: string: 要添加的元素种类，必须是 ````
"button"````
、````
"sprite-button"````
  
````
"checkbox"````
、````
"flow"````
、````
"frame"````
、````
"label"````
、````
"progressbar"````
、````
"table"````
、````
"textfield"````
  
````
"radiobutton"````
、````
"sprite"````
、````
"scroll-pane"````
、````
"drop-down"````
、````
"list-box"````
、````
"camera"````
  
````
"choose-elem-button"````
、````
"text-box"````
、````
"slider"````
、````
"minimap"````
或 ````
"entity-preview"````
之一。  
name :: string: 子元素的名称。  
caption :: LocalisedString (可选): 显示在子元素上的文本。对于 frame，这是“标题”。对于其他元素（如按钮和标签），这是内容。虽然此属性可用于所有元素，但对 table 和 flow 没有意义，因为它们不会显示它。  
tooltip :: LocalisedString (可选): 子元素的提示文本。  
enabled :: boolean (可选): 子元素是否启用。  
ignored_by_interaction :: boolean (可选): 子元素是否被交互忽略。  
style :: string (可选): 新元素的样式。  
根据 ````
type````
的不同，可能还需要指定其他属性。  
button  
mouse_button_filter :: MouseButtonFlags (可选): 按钮响应哪些鼠标按键。  
flow  
direction :: string: flow 布局的初始方向。参见 LuaGuiElement::direction。  
frame  
direction :: string: frame 布局的初始方向。参见 LuaGuiElement::direction。  
table  
column_count :: uint: 列数。  
draw_vertical_lines :: boolean (可选): table 是否绘制垂直网格线。未给出时默认为 ````
false````
。  
draw_horizontal_lines :: boolean (可选): table 是否绘制水平网格线。未给出时默认为 ````
false````
。  
draw_horizontal_line_after_headers :: boolean (可选): table 是否在表头之后绘制水平网格线。未给出时默认为 ````
false````
。  
vertical_centering :: boolean (可选): 此 table 的字段是否垂直居中。未给出时默认为 ````
true````
。  
textfield  
text :: string (可选): textfield 中包含的初始文本。  
progressbar  
value :: double (可选): progressbar 的初始值，范围为 [0, 1]。未给出时默认为 0。  
checkbox  
state :: boolean: checkbox 是否默认勾选。  
radiobutton  
state :: boolean: radiobutton 是否默认选中。  
sprite-button  
sprite :: SpritePath (可选): 要显示在按钮上的图片路径。  
hovered_sprite :: SpritePath (可选): 鼠标悬停在按钮上时显示的图片路径。  
clicked_sprite :: SpritePath (可选): 点击按钮时显示的图片路径。  
number :: double (可选): 按钮上显示的数字。  
show_percent_for_small_numbers :: boolean (可选): 将小数字格式化为百分比。未给出时默认为 ````
false````
。  
mouse_button_filter :: MouseButtonFlags (可选): 按钮响应哪些鼠标按键。  
sprite  
sprite :: SpritePath (可选): 要显示的图片路径。  
scroll-pane  
horizontal_scroll_policy :: string (可选): 水平滚动条的策略，可能的值为 "auto"（默认）、"never"、"always"、"auto-and-reserve-space"。  
vertical_scroll_policy :: string (可选): 垂直滚动条的策略，可能的值为 "auto"（默认）、"never"、"always"、"auto-and-reserve-space"。  
drop-down  
items :: LocalisedString 数组 (可选): 下拉框中的初始项目。  
selected_index :: uint (可选): 初始选中的索引。  
list-box  
items :: LocalisedString 数组 (可选): 列表框中的初始项目。  
selected_index :: uint (可选): 初始选中的索引。  
camera  
position :: Position: camera 对准的位置。  
surface_index :: uint (可选): camera 将渲染的地表；如果未给出，则使用玩家的地表。  
zoom :: double (可选): camera 的缩放级别 - 默认为 0.75。  
choose-elem-button  
elem_type :: string: "item"、"tile"、"entity"、"signal"、"fluid" 或 "recipe"。  
item :: string (可选): 如果 type 为 "item" - 按钮的默认值。  
tile :: string (可选): 如果 type 为 "tile" - 按钮的默认值。  
entity :: string (可选): 如果 type 为 "entity" - 按钮的默认值。  
signal :: SignalID (可选): 如果 type 为 "signal" - 按钮的默认值。  
fluid :: string (可选): 如果 type 为 "fluid" - 按钮的默认值。  
recipe :: string (可选): 如果 type 为 "recipe" - 按钮的默认值。  
text-box  
text :: string (可选): text-box 中包含的初始文本。  
slider  
minimum_value :: double (可选): slider 的最小值  
maximum_value :: double (可选): slider 的最大值  
value :: double (可选): slider 的初始值  
minimap  
position :: Position (可选): minimap 对准的位置；如果未给出，则以拥有此元素的玩家为中心。  
surface_index :: uint (可选): camera 将渲染的地表；如果未给出，则使用玩家的地表。  
chart_player_index :: uint (可选): 地图应使用的玩家索引；如果未设置，则使用拥有此元素的玩家。  
force :: string (可选): 此 minimap 应使用的势力；如果未给出，则使用拥有此元素的玩家的势力。  
zoom :: double (可选): camera 的缩放级别 - 默认为 0.75。
function LuaGuiElement:add(type) end

--- 在此 drop-down 或 list-box 的末尾或指定索引处添加一个条目。
--- 参数
--- LocalisedString: 该条目。
--- index :: uint (可选): 索引
---@param index integer? 索引
---@param LocalisedString table 物品。
function LuaGuiElement:add_item(index, LocalisedString) end

--- 移除此元素的子元素。任何引用已销毁元素的 LuaGuiElement 对象在此操作后将失效。
--- 示例
--- game.player.gui.top.clear()
function LuaGuiElement:clear(...) end

--- 清除此 drop-down 或 list-box 中的条目。
function LuaGuiElement:clear_items(...) end

--- 移除此元素及其子元素。任何引用已销毁元素的 LuaGuiElement 对象在此操作后将失效。
--- 注意： 顶层 GUI 元素——LuaGui::top、LuaGui::left、LuaGui::center——可以被销毁。
--- 示例
--- game.player.gui.top.greeting.destroy()
function LuaGuiElement:destroy(...) end

--- 尽可能聚焦此 GUI 元素。
function LuaGuiElement:focus(...) end

--- 从此 drop-down 或 list-box 中获取指定索引处的条目。
--- 参数
--- index :: uint: 要获取的索引。
---@return table result
---@param index integer 要获取的索引。
function LuaGuiElement:get_item(index) end

--- 获取此 slider 的最小值。
---@return number count
function LuaGuiElement:get_slider_maximum(...) end

--- 获取此 slider 的最小值。
---@return number count
function LuaGuiElement:get_slider_minimum(...) end

--- 移除此 drop-down 或 list-box 中指定索引处的条目。
--- 参数
--- index :: uint: 索引
---@param index integer 索引
function LuaGuiElement:remove_item(index) end

--- 将滚动条滚动到底部。
--- _仅当此元素是 scroll-pane 或 text-box 时才可使用_
function LuaGuiElement:scroll_to_bottom(...) end

--- 滚动滚动条，使指定的 GUI 元素对玩家可见。
--- 参数
--- element :: LuaGuiElement: 要滚动到的元素。
--- scroll_mode :: string (可选): 元素应位于 scroll-pane 中的位置。必须是
--- "in-view"
--- 或
--- "top-third"
--- 之一。默认为
--- "in-view"
--- 。
--- _仅当此元素是 scroll-pane 时才可使用_
---@param element LuaGuiElement 要滚动到的元素。
---@param scroll_mode string? 元素在 scroll-pane 中的位置。必须是 ````
"in-view"````
或 ````
"top-third"````
之一。默认为 ````
"in-view"````
。
function LuaGuiElement:scroll_to_element(element, scroll_mode) end

--- 将滚动条滚动到最左侧。
--- _仅当此元素是 scroll-pane 或 text-box 时才可使用_
function LuaGuiElement:scroll_to_left(...) end

--- 将滚动条滚动到最右侧。
--- _仅当此元素是 scroll-pane 或 text-box 时才可使用_
function LuaGuiElement:scroll_to_right(...) end

--- 将滚动条滚动到顶部。
--- _仅当此元素是 scroll-pane 或 text-box 时才可使用_
function LuaGuiElement:scroll_to_top(...) end

--- 在文本框中选中一段文本。
--- 参数
--- start :: int: 要选中的第一个字符的索引。
--- end :: int: 要选中的最后一个字符的索引。
--- 示例
--- 从
--- example 中选中字符
--- amp
--- textbox.select(3, 5)
--- 示例
--- 将光标移动到文本框的开头
--- textbox.select(1, 0)
--- _仅当此元素是 textfield 或 text-box 时才可使用_
---@param _end integer 要选择的最后一个字符的索引。
---@param start integer 要选择的第一个字符的索引。
function LuaGuiElement:select(_end, start) end

--- 选中文本框中的所有文本。
--- _仅当此元素是 textfield 或 text-box 时才可使用_
function LuaGuiElement:select_all(...) end

--- 设置此 drop-down 或 list-box 中指定索引处的条目。
--- 参数
--- index :: uint: 索引
--- LocalisedString: 该条目。
---@param index integer 索引
---@param LocalisedString table 物品。
function LuaGuiElement:set_item(index, LocalisedString) end

--- 设置此 slider 的最小值和最大值。
--- 参数
--- minimum :: double
--- maximum :: double
--- 注意： 最小值不能 &gt;= 最大值。
---@param maximum number
---@param minimum number
function LuaGuiElement:set_slider_minimum_maximum(maximum, minimum) end

--- 机械臂（机械爪）的控制行为。
---@class LuaInserterControlBehavior
---@field circuit_condition table 电路条件。 注意： 可将 condition 设为 nil 以清除电路条件。 示例 让实体在接收到超过 4 个铁路链式信号灯信号的电路信号时被激活（例如让灯亮起）。 a_behavior.circuit_condition = {condition={comparator=">", first_signal={type="item", name="rail-chain-signal"}, constant=4}}
---@field circuit_hand_read_mode defines.control_behavior.inserter.hand_read_mode 机械臂的手部读取模式。
---@field circuit_mode_of_operation defines.control_behavior.inserter.circuit_mode_of_operation 机械臂的电路工作模式。
---@field circuit_read_hand_contents boolean 如果机械臂手部的内容应发送到电路网络则为 true 。
---@field circuit_set_stack_size boolean 机械臂的堆叠尺寸是否通过电路网络设置。
---@field circuit_stack_control_signal table 用于设置机械臂堆叠尺寸的信号。
---@field connect_to_logistic_network boolean 如果此行为应连接到物流网络则为 true 。
---@field disabled boolean (只读) 实体当前是否因控制行为而被禁用。
---@field entity LuaEntity (只读) 此控制行为所属的实体。
---@field help string 此对象支持的所有方法和属性。
---@field logistic_condition table 物流条件。 注意： 可将 condition 设为 nil 以清除物流条件。 示例 让实体在其连接的物流网络拥有超过 4 个铁路链式信号灯信号时被激活（例如让灯亮起）。 a_behavior.logistic_condition = {condition={comparator=">", first_signal={type="item", name="rail-chain-signal"}, constant=4}}
---@field type defines.control_behavior.type (只读) 此控制行为的具体类型。
---@field valid boolean (只读) 此对象是否有效？
LuaInserterControlBehavior = {}

--- 参数
--- wire :: defines.wire_type: 连接到该实体的网络的导线颜色。
--- circuit_connector :: defines.circuit_connector_id (可选): 要获取电路网络的连接器。
--- 对于拥有多个电路网络连接器的实体必须指定。
--- 返回值
--- 电路网络或 nil。
---@return LuaCircuitNetwork result
---@param circuit_connector defines.circuit_connector_id? 要获取其电路网络的连接器。
对于拥有多个电路网络连接器的实体，必须指定此项。
---@param wire defines.wire_type 连接到此实体的网络的导线颜色。
function LuaInserterControlBehavior:get_circuit_network(circuit_connector, wire) end

--- 物品堆叠（item stacks）的存储容器。
---@class LuaInventory
---@field entity_owner LuaEntity (只读) 拥有此物品栏（inventory）的实体（entity）；如果不是由实体拥有，则为 nil。
---@field equipment_owner LuaEntity (只读) 拥有此物品栏（inventory）的装备（equipment）；如果不是由装备拥有，则为 nil。
---@field help string 此对象支持的所有方法和属性。
---@field index integer (只读) 此物品栏（inventory）使用的物品栏索引。
---@field _operator___ LuaItemStack (只读) 索引运算符。 示例 获取玩家（player）主物品栏（inventory）中的第一个物品： game.player.get_main_inventory()[1]
---@field _operator__ integer (只读) 获取此物品栏（inventory）中的槽位数量。 示例 打印玩家（player）主物品栏（inventory）中的槽位数量： game.player.print(#game.player.get_main_inventory())
---@field player_owner LuaPlayer (只读) 拥有此物品栏（inventory）的玩家（player）；如果不是由玩家拥有，则为 nil。
---@field valid boolean (只读) 此对象是否有效？
LuaInventory = {}

--- 是否至少可以插入部分物品？
--- 参数
--- items :: ItemStackSpecification：将要插入的物品。
--- 返回值
--- 如果给定物品中至少有一部分可以被插入到此物品栏（inventory）中，则返回
--- true。
---@return boolean ok
---@param items table 将要插入的物品。
function LuaInventory:can_insert(items) end

--- 是否可以将给定物品栏（inventory）槽位的过滤器设置为给定的过滤器。
--- 参数
--- index :: uint：物品堆叠的索引
--- filter :: string：过滤器的物品名
---@return boolean ok
---@param filter string 过滤器的物品名称
---@param index integer 物品堆叠索引
function LuaInventory:can_set_filter(filter, index) end

--- 清空此物品栏（inventory）。
function LuaInventory:clear(...) end

--- 获取物品栏（inventory）中与给定物品名匹配的第一个 LuaItemStack。
--- 参数
--- item :: string：要查找的物品名
--- 返回值
--- 匹配的 LuaItemStack，否则为
--- nil。
--- 注意： 如果找到匹配的堆叠，还会将堆叠索引作为第二个返回值返回。
---@return LuaItemStack itemStack
---@param item string 要查找的物品名称
function LuaInventory:find_item_stack(item) end

--- 获取此物品栏（inventory）中所有物品的数量。
--- 返回值
--- 以物品名为索引的数量。
---@return table<string, integer> count
function LuaInventory:get_contents(...) end

--- 获取给定物品堆叠索引的过滤器。
--- 参数
--- index :: uint：物品堆叠的索引
--- 返回值
--- 当前的过滤器；如果没有则为 nil。
---@return string result
---@param index integer 物品堆叠索引
function LuaInventory:get_filter(index) end

--- 获取此物品栏（inventory）中全部或部分物品的数量。
--- 参数
--- item :: string（可选）：要计数的物品的原型（prototype）名。如果未指定，则统计所有物品。
---@return integer count
---@param item string? 要计数的物品的原型名称。如果未指定，则统计所有物品。
function LuaInventory:get_item_count(item) end

--- 获取当前的条（bar）。这是红色区域开始处的索引。
--- 注意： 仅当此物品栏（inventory）有条（bar）时才可用。
---@return integer count
function LuaInventory:getbar(...) end

--- 此物品栏（inventory）是否有一个条（bar）？条（bar）是可拖动的红色部件，例如在箱子（chest）上可以看到，它限制了机器可以操作的物品栏（inventory）部分。
--- 注意： "有条（bar）"并不意味着条被设置为某个非平凡的值。有条（bar）意味着物品栏完全支持这种限制。角色（character）的物品栏是没有条（bar）的物品栏的示例；木箱的物品栏是有条（bar）的物品栏的示例。
---@return boolean ok
function LuaInventory:hasbar(...) end

--- 将物品插入此物品栏（inventory）。
--- 参数
--- items :: ItemStackSpecification：要插入的物品。
--- 返回值
--- 实际插入的物品数量。
---@return integer count
---@param items table 要插入的物品。
function LuaInventory:insert(items) end

--- 此物品栏（inventory）是否为空？
---@return boolean ok
function LuaInventory:is_empty(...) end

--- 此物品栏（inventory）是否支持过滤器且至少设置了一个过滤器。
---@return boolean ok
function LuaInventory:is_filtered(...) end

--- 从此物品栏（inventory）中移除物品。
--- 参数
--- items :: ItemStackSpecification：要移除的物品。
--- 返回值
--- 实际移除的物品数量。
---@return integer count
---@param items table 要移除的物品。
function LuaInventory:remove(items) end

--- 为给定的物品堆叠索引设置过滤器。
--- 参数
--- index :: uint：物品堆叠的索引
--- filter :: string：新的过滤器；传 nil 可清除过滤器
--- 返回值
--- 过滤器是否被允许设置。
--- 注意： 某些物品栏（inventory）槽位不允许某些过滤器（例如枪支弹药不能被设置为非弹药过滤器）。
---@return boolean ok
---@param filter string 新的过滤器，或传入 nil 以清除过滤器
---@param index integer 物品堆叠索引
function LuaInventory:set_filter(filter, index) end

--- 设置当前的条（bar）。
--- 参数
--- bar :: uint（可选）：新的限制。省略此参数将清除限制。
--- 注意： 仅当此物品栏（inventory）有条（bar）时才可用。
---@param bar integer? 新的上限。省略此参数将清除该上限。
function LuaInventory:setbar(bar) end

--- 对此物品栏（inventory）中的物品进行排序和合并。
function LuaInventory:sort_and_merge(...) end

--- 此物品栏（inventory）是否支持过滤器。
---@return boolean ok
function LuaInventory:supports_filters(...) end

--- 物品的原型（prototype）。
---@class LuaItemPrototype
---@field alt_entity_filter_mode string (只读) 此选择工具（selection tool）使用的备用实体（entity）过滤器模式。 _仅当这是 SelectionTool 时才可使用_
---@field alt_entity_filters table<string, LuaEntityPrototype> (只读) 此选择工具（selection tool）使用的备用实体（entity）过滤器，以实体名为索引。 _仅当这是 SelectionTool 时才可使用_
---@field alt_entity_type_filters table<string, boolean> (只读) 此选择工具（selection tool）使用的备用实体（entity）类型过滤器，以实体类型为索引。 注意： 布尔值没有实际意义，仅用于方便在字典中查找某个类型是否存在。 _仅当这是 SelectionTool 时才可使用_
---@field alt_selection_border_color table (只读) 使用此选择工具（selection tool）原型（prototype）进行备用选择时使用的颜色。 _仅当这是 SelectionTool 时才可使用_
---@field alt_selection_cursor_box_type string (只读) _仅当这是 SelectionTool 时才可使用_
---@field alt_selection_mode_flags table (只读) 影响在备用选择期间将选中哪些实体（entity）的标志。 _仅当这是 SelectionTool 时才可使用_
---@field alt_tile_filter_mode string (只读) 此选择工具（selection tool）使用的备用地块（tile）过滤器模式。 _仅当这是 SelectionTool 时才可使用_
---@field alt_tile_filters table<string, LuaTilePrototype> (只读) 此选择工具（selection tool）使用的备用地块（tile）过滤器，以地块名为索引。 _仅当这是 SelectionTool 时才可使用_
---@field always_include_tiles boolean (只读) 使用此选择工具（selection tool）原型（prototype）进行选择时是否始终包含地块（tile）。 _仅当这是 SelectionTool 时才可使用_
---@field attack_parameters table (只读) 枪支攻击参数；如果不是枪支物品原型（prototype），则为 nil。
---@field burnt_result LuaItemPrototype (只读) 将此物品作为燃料燃烧后的结果；否则为 nil。
---@field can_be_mod_opened boolean (只读) 此物品是否可以被 mod 打开。
---@field capsule_action table (只读) 此胶囊（capsule）物品原型（prototype）的胶囊动作；如果不是胶囊物品原型（prototype），则为 nil。
---@field category string (只读) 模块（module）类别名。 _仅当这是 ModuleItem 时才可使用_
---@field curved_rail LuaEntityPrototype (只读) 此铁路规划器（rail planner）原型（prototype）使用的弯轨原型（prototype）。 _仅当这是 RailPlanner 时才可使用_
---@field default_label_color table (只读) 此带标签（label）物品使用的默认标签颜色。如果未定义或这不是带标签的物品，则为 nil。 _仅当这是 ItemWithLabel 时才可使用_
---@field default_request_amount integer (只读) 默认请求值。
---@field draw_label_for_cursor_render boolean (只读) 如果为 true，并且此带标签（label）物品有标签，那么在手持时将以标签代替常规数字绘制。 _仅当这是 ItemWithLabel 时才可使用_
---@field durability number (只读) 此工具（tool）物品的耐久度；如果不是工具物品，则为 nil。 _仅当这是 ToolItem 时才可使用_
---@field durability_description_key string (只读) 显示此工具（tool）耐久度时使用的耐久度消息键。 _仅当这是 ToolItem 时才可使用_
---@field entity_filter_mode string (只读) 此选择工具（selection tool）使用的实体（entity）过滤器模式。 _仅当这是 SelectionTool 时才可使用_
---@field entity_filter_slots integer (只读) 此拆除（deconstruction）物品拥有的实体（entity）过滤器数量；如果不是拆除物品原型（prototype），则为 nil。 _仅当这是 DeconstructionItem 时才可使用_
---@field entity_filters table<string, LuaEntityPrototype> (只读) 此选择工具（selection tool）使用的实体（entity）过滤器，以实体名为索引。 _仅当这是 SelectionTool 时才可使用_
---@field entity_type_filters table<string, boolean> (只读) 此选择工具（selection tool）使用的实体（entity）类型过滤器，以实体类型为索引。 注意： 布尔值没有实际意义，仅用于方便在字典中查找某个类型是否存在。 _仅当这是 SelectionTool 时才可使用_
---@field equipment_grid LuaEquipmentGridPrototype (只读) 此护甲（armor）装备网格（equipment grid）的原型（prototype）；如果没有或这不是护甲物品，则为 nil。
---@field extend_inventory_by_default boolean (只读) 此带物品栏（inventory）的物品是否默认扩展其所处的物品栏。 _仅当这是 ItemWithInventory 时才可使用_
---@field filter_mode string (只读) 此带物品栏（inventory）的物品使用的过滤器模式。 _仅当这是 ItemWithInventory 时才可使用_
---@field flags table<string, boolean> (只读) 此物品原型（prototype）的物品原型标志。它是一个字典，键为已设置的标志，值始终为 true——如果某个标志未设置，它根本不会出现在字典中。可能的标志有： "hidden" ：如果为 true，该物品将从所有制造（crafting）菜单中隐藏。
---@field fuel_acceleration_multiplier number (只读) 此物品在载具（vehicle）中用作燃料时的加速度倍率。
---@field fuel_category string (只读) 燃料类别；否则为 nil。
---@field fuel_emissions_multiplier number (只读) 此物品用作燃料时的排放倍率。
---@field fuel_top_speed_multiplier number (只读) 此物品在载具（vehicle）中用作燃料时的最高速度倍率。
---@field fuel_value number (只读) 燃烧时的燃料值。
---@field group LuaGroup (只读) 此原型（prototype）所属的组。
---@field help string 此对象支持的所有方法和属性。
---@field infinite boolean (只读) 此工具（tool）物品是否具有无限耐久度。如果不是工具类型物品，则为 nil。 _仅当这是 ToolItem 时才可使用_
---@field insertion_priority_mode string (只读) 此带物品栏（inventory）的物品使用的插入优先级模式。 _仅当这是 ItemWithInventory 时才可使用_
---@field inventory_size integer (只读) 带物品栏（inventory）原型（prototype）的物品的主物品栏大小。如果不是带物品栏原型（prototype）的物品，则为 nil。 _仅当这是 ItemWithInventoryPrototype 时才可使用_
---@field inventory_size_bonus integer (只读) 此护甲（armor）原型（prototype）的物品栏（inventory）大小加成。如果不是护甲原型（prototype），则为 nil。 _仅当这是 ArmorPrototype 时才可使用_
---@field item_filters table<string, LuaItemPrototype> (只读) _仅当这是 ItemWithInventory 时才可使用_
---@field item_group_filters table<string, LuaGroup> (只读) _仅当这是 ItemWithInventory 时才可使用_
---@field item_subgroup_filters table<string, LuaGroup> (只读) _仅当这是 ItemWithInventory 时才可使用_
---@field limitation_message_key string (只读) 当玩家（player）尝试在不允许使用此模块（module）的地方使用它时显示的限制消息键。 _仅当这是 ModuleItem 时才可使用_
---@field limitations string[] (只读) 此模块（module）被允许生效的配方（recipe）名数组。 _仅当这是 ModuleItem 时才可使用_
---@field localised_description table (只读)
---@field localised_filter_message table (只读) 当玩家（player）尝试将不允许的物品放入此带物品栏（inventory）的物品时使用的本地化字符串。 _仅当这是 ItemWithInventory 时才可使用_
---@field localised_name table (只读)
---@field magazine_size number (只读) 满弹匣的容量；如果不是弹药（ammo）物品，则为 nil。
---@field mapper_count integer (只读) 升级（upgrade）物品拥有多少个过滤器。如果不是升级物品，则为 nil。 _仅当这是 UpgradeItem 时才可使用_
---@field module_effects table (只读) 此模块（module）的效果；如果不是模块，则为 nil。它是一个以效果类型为索引的字典。 _仅当这是 ModuleItem 时才可使用_
---@field name string (只读) 此原型（prototype）的名称。
---@field order string (只读) 排序字符串。
---@field place_as_equipment_result LuaEquipmentPrototype (只读) 将此物品放置到装备网格（equipment grid）中时将创建的装备（equipment）原型（prototype）；如果未定义装备，则为 nil。
---@field place_as_tile_result table (只读) 作为地块（tile）放置的结果；如果已定义则返回该结果，否则为 nil。
---@field place_result LuaEntityPrototype (只读) 放置此物品时将创建的实体（entity）原型（prototype）；如果没有这样的实体，则为 nil。
---@field reload_time number (只读) 弹匣耗尽后重新装填武器所需的额外时间（以 tick 计）；如果不是弹药（ammo）物品，则为 nil。
---@field repair_result table (只读) 此维修（repair）工具原型（prototype）的维修结果；如果不是维修工具原型（prototype），则为 nil。 _仅当这是 RepairTool 时才可使用_
---@field resistances table (只读) 此护甲（armor）物品的抗性；如果不是护甲或护甲没有抗性，则为 nil。
---@field robot_action table (只读) 此胶囊（capsule）物品原型（prototype）的机器人（robot）动作；如果不是胶囊物品原型（prototype），则为 nil。
---@field rocket_launch_products table[] (只读) 在火箭（rocket）中发射此物品的结果。
---@field selection_border_color table (只读) 使用此选择工具（selection tool）原型（prototype）进行常规选择时使用的颜色。 _仅当这是 SelectionTool 时才可使用_
---@field selection_cursor_box_type string (只读) _仅当这是 SelectionTool 时才可使用_
---@field selection_mode_flags table (只读) 影响将选中哪些实体（entity）的标志。 _仅当这是 SelectionTool 时才可使用_
---@field show_in_library boolean (只读) 此选择工具（selection tool）原型（prototype）是否在蓝图（blueprint）库中可用。如果不是选择工具或蓝图书，则为 nil。
---@field speed number (只读) 如果这是维修（repair）工具，则为维修速度；否则为 nil。
---@field stack_size integer (只读) 此原型（prototype）指定的物品的最大堆叠大小。
---@field stackable boolean (只读) 此物品是否允许堆叠？
---@field straight_rail LuaEntityPrototype (只读) 此铁路规划器（rail planner）原型（prototype）使用的直轨原型（prototype）。 _仅当这是 RailPlanner 时才可使用_
---@field subgroup LuaGroup (只读) 此原型（prototype）所属的子组。
---@field tier number (只读) 模块（module）等级。 _仅当这是 ModuleItem 时才可使用_
---@field tile_filter_mode string (只读) 此选择工具（selection tool）使用的地块（tile）过滤器模式。 _仅当这是 SelectionTool 时才可使用_
---@field tile_filter_slots integer (只读) 此拆除（deconstruction）物品拥有的地块（tile）过滤器数量；如果不是拆除物品原型（prototype），则为 nil。 _仅当这是 DeconstructionItem 时才可使用_
---@field tile_filters table<string, LuaTilePrototype> (只读) 此选择工具（selection tool）使用的地块（tile）过滤器，以地块名为索引。 _仅当这是 SelectionTool 时才可使用_
---@field type string (只读) 此原型（prototype）的类型。例如 "gun" 或 "mining-tool" 。
---@field valid boolean (只读) 此对象是否有效？
---@field wire_count integer (只读) 使用此物品作为电线（wire）连接 2 个实体（entity）所需的物品数量。
LuaItemPrototype = {}

--- 此弹药（ammo）原型（prototype）的类型；如果不是弹药原型（prototype），则为
--- nil。
--- 参数
--- ammo_source_type :: string（可选）："default"、"player"、"turret" 或 "vehicle"
---@return table result
---@param ammo_source_type string? "default"、"player"、"turret" 或 "vehicle"
function LuaItemPrototype:get_ammo_type(ammo_source_type) end

--- 此原型（prototype）是否启用了某个标志？任何其他值都会导致错误。
--- 参数
--- flag :: string：要检查的标志。可以是
--- "hidden"
--- 、
--- "hide-from-bonus-gui"
--- 或
--- "hide-from-fuel-tooltip"
--- 。
---@return boolean ok
---@param flag string 要检查的标记。可以是 "hidden"、"hide-from-bonus-gui" 或 "hide-from-fuel-tooltip"。
function LuaItemPrototype:has_flag(flag) end

--- 对由某个外部实体（entity）拥有的物品及其数量的引用。
---@class LuaItemStack
---@field active_index integer 此蓝图（blueprint）书当前激活的蓝图索引。 _仅当这是 BlueprintBookItem 时才可使用_
---@field allow_manual_label_change boolean 此物品的标签（label）是否可以被手动更改。当为 false 时，标签只能通过 API 更改。 _仅当这是 ItemWithLabel 时才可使用_
---@field ammo integer 弹匣中剩余的子弹数量。 _仅当这是 AmmoItem 时才可使用_
---@field blueprint_icons table[] 蓝图（blueprint）物品的图标。此数组中的每个条目都包含以下字段： signal :: SignalID：要使用的槽位图标。该槽位将显示指定信号的图标。这允许使用任何物品图标以及虚拟信号图标。 index :: uint：图标在蓝图图标槽位中的索引。必须在 {1, 2, 3, 4} 中。 _仅当这是 BlueprintItem 时才可使用_
---@field cost_to_build table<string, integer> (只读) 建造此蓝图（blueprint）所需的原材料。结果是一个将每个物品原型（prototype）名映射到所需数量的字典。 _仅当这是 BlueprintItem 时才可使用_
---@field count integer 此堆叠中的物品数量。
---@field custom_description table 此带标签（tags）物品的自定义描述。如果设置为非空值，它将显示在常规物品描述之上。
---@field default_icons table[] (只读) 蓝图（blueprint）物品的默认图标。此数组中的每个条目都包含以下字段： name :: string：要使用其图标的物品的原型（prototype）名 index :: uint：图标在蓝图图标槽位中的索引。必须在 {1, 2, 3, 4} 中。 _仅当这是 BlueprintItem 时才可使用_
---@field durability number 所含物品的耐久度。会自动限制在该物品的最大耐久度。 注意： 当用于非工具（tool）物品时，此属性的值为 nil。
---@field entity_filter_count integer (只读) 此拆除（deconstruction）物品支持的实体（entity）过滤器数量。 _仅当这是 DeconstructionItem 时才可使用_
---@field entity_filter_mode defines.deconstruction_item.entity_filter_mode 此拆除（deconstruction）物品的黑名单/白名单实体（entity）过滤器模式。 _仅当这是 DeconstructionItem 时才可使用_
---@field entity_filters string[] 此拆除（deconstruction）物品的实体（entity）过滤器。
---@field extends_inventory boolean 此物品是否扩展其所处的物品栏（inventory）（将其内容用于计数、制造（crafting）、插入）。仅可在带物品栏的物品上调用。 _仅当这是 ItemWithInventory 时才可使用_
---@field grid LuaEquipmentGrid (只读) 此物品的装备网格（equipment grid）；如果此物品没有网格，则为 nil。
---@field health number 物品拥有多少生命值（health），为 [0, 1] 范围内的数字。
---@field help string 此对象支持的所有方法和属性。
---@field is_armor boolean (只读) 这是否是护甲（armor）物品。
---@field is_blueprint boolean (只读) 这是否是蓝图（blueprint）物品。
---@field is_blueprint_book boolean (只读) 这是否是蓝图（blueprint）书物品。
---@field is_deconstruction_item boolean (只读) 这是否是拆除（deconstruction）工具物品。
---@field is_item_with_entity_data boolean (只读) 这是否是带实体（entity）数据的物品。
---@field is_item_with_inventory boolean (只读) 这是否是带物品栏（inventory）的物品。
---@field is_item_with_label boolean (只读) 这是否是带标签（label）的物品。
---@field is_item_with_tags boolean (只读) 这是否是带标签（tags）的物品。
---@field is_mining_tool boolean (只读) 这是否是采矿（mining）工具物品。
---@field is_module boolean (只读) 这是否是模块（module）物品。
---@field is_repair_tool boolean (只读) 这是否是维修（repair）工具物品。
---@field is_selection_tool boolean (只读) 这是否是选择工具（selection tool）物品。
---@field is_tool boolean (只读) 这是否是工具（tool）物品。
---@field is_upgrade_item boolean (只读) 这是否是升级（upgrade）物品。
---@field item_number integer (只读) 此物品的唯一 ID（如果它有唯一 ID）；否则为 nil。 以下物品类型具有唯一 ID： "armor" "blueprint" "blueprint-book" "deconstruction-item" "item-with-entity-data" "item-with-inventory" "selection-tool" "item-with-tags"
---@field label string 此物品当前的标签（label）。没有时为 Nil。 _仅当这是 ItemWithLabel 时才可使用_
---@field label_color table 此物品当前的标签（label）颜色。没有时为 Nil。 _仅当这是 ItemWithLabel 时才可使用_
---@field name string (只读) 此堆叠中持有的物品的原型（prototype）名。
---@field prioritize_insertion_mode string 当物品被插入到其所处的物品栏（inventory）时，此 ItemWithInventory 使用的插入模式优先级。仅可在带物品栏的物品上调用。 _仅当这是 ItemWithInventory 时才可使用_
---@field prototype LuaItemPrototype (只读) 此堆叠中持有的物品的原型（prototype）。
---@field tags table<string, any> _仅当这是 ItemWithTags 时才可使用_
---@field tile_filter_count integer (只读) 此拆除（deconstruction）物品支持的地块（tile）过滤器数量。 _仅当这是 DeconstructionItem 时才可使用_
---@field tile_filter_mode defines.deconstruction_item.tile_filter_mode 此拆除（deconstruction）物品的黑名单/白名单地块（tile）过滤器模式。 _仅当这是 DeconstructionItem 时才可使用_
---@field tile_filters string[] 此拆除（deconstruction）物品的地块（tile）过滤器。
---@field tile_selection_mode defines.deconstruction_item.tile_selection_mode 此拆除（deconstruction）物品的地块（tile）选择模式。 _仅当这是 DeconstructionItem 时才可使用_
---@field trees_and_rocks_only boolean 此拆除（deconstruction）物品是否设置为仅允许树木和岩石。 _仅当这是 DeconstructionItem 时才可使用_
---@field type string (只读) 物品原型（prototype）的类型。
---@field valid boolean (只读) 此对象是否有效？
---@field valid_for_read boolean (只读) 此对象是否可安全读取？与通常的 valid 不同之处在于：即使物品堆叠是空的，但持有它的实体（entity）仍然有效时， valid 仍为 true。
LuaItemStack = {}

--- 为此弹药（ammo）物品添加弹药。
--- 参数
--- amount :: uint：要添加的弹药数量。
--- _仅当这是 AmmoItem 时才可使用_
---@param amount integer 要添加的弹药量。
function LuaItemStack:add_ammo(amount) end

--- 为此工具（tool）物品添加耐久度。
--- 参数
--- amount :: double：要添加的耐久度数量。
--- _仅当这是 ToolItem 时才可使用_
---@param amount number 要添加的耐久度。
function LuaItemStack:add_durability(amount) end

--- 建造此蓝图（blueprint）。
--- 参数
--- 包含以下字段的表：
--- surface :: SurfaceSpecification：要建造的地表（surface）
--- force :: ForceSpecification：建造时使用的势力（force）
--- position :: Position：建造的位置
--- force_build :: boolean（可选）：当为 true 时，任何可以建造的都会被建造；否则如果任意一个无法建造，则什么都不建造
--- direction :: defines.direction（可选）：建造时使用的方向
--- skip_fog_of_war :: boolean（可选）：是否跳过被战争迷雾覆盖的区块（chunk）。
--- by_player :: PlayerSpecification（可选）：如有需要，使用的玩家（player）。
--- 返回值
--- 创建的虚影（ghost）数组
---@return LuaEntity[] entity
---@param surface table? surface :: SurfaceSpecification: 要建造的地表  
force :: ForceSpecification: 建造所使用的势力  
position :: Position: 建造的位置  
force_build :: boolean (可选): 为 true 时，任何能建造的东西都会被建造；否则，只要有一样东西无法建造，就什么都不建造  
direction :: defines.direction (可选): 建造时使用的方向  
skip_fog_of_war :: boolean (可选): 是否跳过处于战争迷雾中的区块。  
by_player :: PlayerSpecification (可选): 需要时使用的玩家。
function LuaItemStack:build_blueprint(surface) end

--- 调用 LuaItemStack::set_stack 是否会成功？
--- 参数
--- stack :: ItemStackSpecification（可选）：将要设置的堆叠，可能为
--- nil。
---@return boolean ok
---@param stack table? 将要设置的物品堆叠，可能为 nil。
function LuaItemStack:can_set_stack(stack) end

--- 使用此拆除（deconstruction）物品取消拆除给定的区域。
--- 参数
--- 包含以下字段的表：
--- surface :: SurfaceSpecification：要取消拆除的地表（surface）
--- force :: ForceSpecification：取消拆除时使用的势力（force）
--- area :: BoundingBox：要拆除的区域
--- skip_fog_of_war :: boolean（可选）：是否跳过被战争迷雾覆盖的区块（chunk）。
--- by_player :: PlayerSpecification（可选）：如有需要，使用的玩家（player）。
---@param surface table? surface :: SurfaceSpecification: 要取消拆除的地表  
force :: ForceSpecification: 取消拆除所使用的势力  
area :: BoundingBox: 要取消拆除的区域  
skip_fog_of_war :: boolean (可选): 是否跳过处于战争迷雾中的区块。  
by_player :: PlayerSpecification (可选): 需要时使用的玩家。
function LuaItemStack:cancel_deconstruct_area(surface) end

--- 清空此物品堆叠。
function LuaItemStack:clear(...) end

--- 清空此蓝图（blueprint）物品。
--- _仅当这是 BlueprintItem 时才可使用_
function LuaItemStack:clear_blueprint(...) end

--- 清除此拆除（deconstruction）物品上的所有设置/过滤器，将其重置为默认值。
--- _仅当这是 DeconstructionItem 时才可使用_
function LuaItemStack:clear_deconstruction_item(...) end

--- 清除此升级（upgrade）物品上的所有设置/过滤器，将其重置为默认值。
--- _仅当这是 UpgradeItem 时才可使用_
function LuaItemStack:clear_upgrade_item(...) end

--- 使用地表（surface）上找到的可蓝图化实体（entity）/地块（tile）来设置此蓝图（blueprint）。
--- 参数
--- 包含以下字段的表：
--- surface :: SurfaceSpecification：要从中创建的地表（surface）
--- force :: ForceSpecification：创建时使用的势力（force）
--- area :: BoundingBox：边界框
--- always_include_tiles :: boolean（可选）：当为 true 时，可蓝图化的地块（tile）始终包含在蓝图中。当为 false 时，仅当设置区域内不存在实体（entity）时才包含它们。
---@param surface table? surface :: SurfaceSpecification: 要从中创建的地表  
force :: ForceSpecification: 创建所使用的势力  
area :: BoundingBox: 边界框  
always_include_tiles :: boolean (可选): 为 true 时，可蓝图化的地块始终包含在蓝图中；为 false 时，仅当设定区域内不存在实体时才包含地块。
function LuaItemStack:create_blueprint(surface) end

--- 使用此拆除（deconstruction）物品拆除给定的区域。
--- 参数
--- 包含以下字段的表：
--- surface :: SurfaceSpecification：要拆除的地表（surface）
--- force :: ForceSpecification：拆除时使用的势力（force）
--- area :: BoundingBox：要拆除的区域
--- skip_fog_of_war :: boolean（可选）：是否跳过被战争迷雾覆盖的区块（chunk）。
--- by_player :: PlayerSpecification（可选）：如有需要，使用的玩家（player）。
---@param surface table? surface :: SurfaceSpecification: 要拆除的地表  
force :: ForceSpecification: 拆除所使用的势力  
area :: BoundingBox: 要拆除的区域  
skip_fog_of_war :: boolean (可选): 是否跳过处于战争迷雾中的区块。  
by_player :: PlayerSpecification (可选): 需要时使用的玩家。
function LuaItemStack:deconstruct_area(surface) end

--- 从此弹药（ammo）物品中移除弹药。
--- 参数
--- amount :: uint：要移除的弹药数量。
--- _仅当这是 AmmoItem 时才可使用_
---@param amount integer 要移除的弹药量。
function LuaItemStack:drain_ammo(amount) end

--- 从此工具（tool）物品中移除耐久度。
--- 参数
--- amount :: double：要移除的耐久度数量。
--- _仅当这是 ToolItem 时才可使用_
---@param amount number 要移除的耐久度。
function LuaItemStack:drain_durability(amount) end

--- 将受支持的物品（蓝图（blueprint）、蓝图书（blueprint-book）、拆除规划器（deconstruction-planner）、升级规划器（upgrade-planner）、带标签物品（item-with-tags））导出为字符串。
--- 返回值
--- 导出的字符串
---@return string result
function LuaItemStack:export_stack(...) end

--- 此蓝图（blueprint）中的实体（entity）。
--- 返回值
--- 实体表（entity table）的字段取决于实体的类型。每个实体至少包含以下字段：
--- entity_number :: uint：实体在此蓝图（blueprint）中的唯一标识符
--- name :: string：实体的原型（prototype）名
--- position :: Position：实体的位置
--- direction :: defines.direction（可选）：实体面对的方向。仅存在于可以面向不同方向的实体中。
--- 其他：实体特有的字段...
--- _仅当这是 BlueprintItem 时才可使用_
---@return table[] count
function LuaItemStack:get_blueprint_entities(...) end

--- 此蓝图（blueprint）中的地块（tile）。
--- 返回值
--- 蓝图（blueprint）地块是一个表：
--- position :: Position
--- name :: string：地块的原型（prototype）名。
--- _仅当这是 BlueprintItem 时才可使用_
---@return table[] count
function LuaItemStack:get_blueprint_tiles(...) end

--- 获取此拆除（deconstruction）物品在给定索引处的实体（entity）过滤器。
--- 参数
--- index :: uint
--- _仅当这是 DeconstructionItem 时才可使用_
---@return string result
---@param index integer
function LuaItemStack:get_entity_filter(index) end

--- 访问物品的内部物品栏（inventory）。
--- 参数
--- inventory :: defines.inventory
--- 要访问的物品栏索引——目前只能是 defines.inventory.item_main。
--- 返回值
--- 如果没有具有给定索引的物品栏，则为
--- nil。
---@return LuaInventory result
---@param inventory defines.inventory
function LuaItemStack:get_inventory(inventory) end

--- 获取此升级（upgrade）物品在给定索引处的过滤器。
--- 参数
--- index :: uint：要读取的映射器（mapper）的索引。
--- type :: string：'from' 或 'to'。
--- _仅当这是 UpgradeItem 时才可使用_
---@return table result
---@param index integer 要读取的映射器（mapper）的索引。
---@param type string 'from' 或 'to'。
function LuaItemStack:get_mapper(index, type) end

--- 获取具有给定名称的标签（tag）；如果不存在则返回
--- nil。
--- 参数
--- tag_name :: string
--- _仅当这是 ItemWithTags 时才可使用_
---@return any result
---@param tag_name string
function LuaItemStack:get_tag(tag_name) end

--- 获取此拆除（deconstruction）物品在给定索引处的地块（tile）过滤器。
--- 参数
--- index :: uint
--- _仅当这是 DeconstructionItem 时才可使用_
---@return string result
---@param index integer
function LuaItemStack:get_tile_filter(index) end

--- 从字符串导入受支持的物品（蓝图（blueprint）、蓝图书（blueprint-book）、拆除规划器（deconstruction-planner）、升级规划器（upgrade-planner）、带标签物品（item-with-tags））。
--- 参数
--- data :: string：要导入的字符串
--- 返回值
--- 如果导入成功且无错误，返回 0。如果导入成功但有错误，返回 -1。如果导入失败，返回 1。
---@return integer count
---@param data string 要导入的字符串
function LuaItemStack:import_stack(data) end

--- 此蓝图（blueprint）物品是否已设置？即它是否是非空蓝图（blueprint）？
---@return boolean ok
function LuaItemStack:is_blueprint_setup(...) end

--- 移除具有给定名称的标签（tag）。
--- 参数
--- tag :: string
--- 返回值
--- 标签（tag）是否存在并被移除。
--- _仅当这是 ItemWithTags 时才可使用_
---@return boolean ok
---@param tag string
function LuaItemStack:remove_tag(tag) end

--- 设置新的实体（entity）作为此蓝图（blueprint）的一部分。
--- 参数
--- entities :: array of blueprint entity：新的蓝图（blueprint）实体。格式与 LuaItemStack::get_blueprint_entities 相同。
--- _仅当这是 BlueprintItem 时才可使用_
---@param entities table[] 新的蓝图实体。格式与 LuaItemStack::get_blueprint_entities 相同。
function LuaItemStack:set_blueprint_entities(entities) end

--- 设置此蓝图（blueprint）中的地块（tile）。
--- 参数
--- tiles :: array of blueprint tile：作为蓝图（blueprint）一部分的地块；格式与对应的 get 函数返回的格式相同；参见 LuaItemStack::get_blueprint_tiles。
--- _仅当这是 BlueprintItem 时才可使用_
---@param tiles table[] 将作为蓝图一部分的地块；格式与对应的 get 函数返回的相同；参见 LuaItemStack::get_blueprint_tiles。
function LuaItemStack:set_blueprint_tiles(tiles) end

--- 为此拆除（deconstruction）物品在给定索引处设置实体（entity）过滤器。
--- 参数
--- index :: uint
--- filter :: string 或 LuaEntityPrototype 或 LuaEntity：设置为 nil 会清除过滤器。
--- 返回值
--- 新过滤器是否已设置（是否有效）。
--- _仅当这是 DeconstructionItem 时才可使用_
---@return boolean ok
---@param filter string | LuaEntityPrototype | LuaEntity 设置为 nil 会清除过滤器。
---@param index integer
function LuaItemStack:set_entity_filter(filter, index) end

--- 为此升级（upgrade）物品在给定索引处设置模块（module）过滤器。
--- 参数
--- index :: uint：要设置的映射器（mapper）的索引。
--- type :: string：
--- from
--- 或
--- to
--- 。
--- filter :: UpgradeFilter：要设置的过滤器或
--- nil
--- _仅当这是 UpgradeItem 时才可使用_
---@param filter table 要设置的过滤器，或 nil
---@param index integer 要设置的映射器（mapper）的索引。
---@param type string "from" 或 "to"。
function LuaItemStack:set_mapper(filter, index, type) end

--- 将此物品堆叠设置为另一个物品堆叠。
--- 参数
--- stack :: ItemStackSpecification（可选）
--- 要将此堆叠设置成的物品堆叠。省略此参数或传入
--- nil
--- 将清空此物品堆叠（相当于调用 LuaItemStack::clear）。
--- 返回值
--- 堆叠是否设置成功？
---@return boolean ok
---@param stack table?
function LuaItemStack:set_stack(stack) end

--- 设置具有给定名称和值的标签（tag）。
--- 参数
--- tag_name :: string
--- tag :: Any
--- _仅当这是 ItemWithTags 时才可使用_
---@return any result
---@param tag any
---@param tag_name string
function LuaItemStack:set_tag(tag, tag_name) end

--- 为此拆除（deconstruction）物品在给定索引处设置地块（tile）过滤器。
--- 参数
--- index :: uint
--- filter :: string 或 LuaTilePrototype 或 LuaTile：设置为 nil 会清除过滤器。
--- 返回值
--- 新过滤器是否已设置（是否有效）。
--- _仅当这是 DeconstructionItem 时才可使用_
---@return boolean ok
---@param filter string | LuaTilePrototype | LuaTile 设置为 nil 会清除过滤器。
---@param index integer
function LuaItemStack:set_tile_filter(filter, index) end

--- 如果允许，将此物品堆叠与给定的物品堆叠交换。
--- 参数
--- stack :: LuaItemStack
--- 返回值
--- 两个堆叠是否成功交换。
---@return boolean ok
---@param stack LuaItemStack
function LuaItemStack:swap_stack(stack) end

--- 将给定的物品堆叠转移到此物品堆叠中。
--- 参数
--- stack :: ItemStackSpecification
--- 返回值
--- 如果整个堆叠都被转移，则返回 True。
---@return boolean ok
---@param stack table
function LuaItemStack:transfer_stack(stack) end

--- 灯（lamp）的控制行为。
---@class LuaLampControlBehavior
---@field circuit_condition table 电路（circuit）条件。 注意： condition 可以设置为 nil 以清除电路条件。 示例 当实体（entity）接收到超过 4 个链信号（chain signal）的电路信号时，让其实体处于激活状态（例如让灯亮起）： a_behavior.circuit_condition = {condition={comparator=">", first_signal={type="item", name="rail-chain-signal"}, constant=4}}
---@field color table (只读) 灯当前显示的颜色；如果未使用任何颜色，则为 nil。
---@field connect_to_logistic_network boolean 如果此设备应连接到物流（logistic）网络，则为 true。
---@field disabled boolean (只读) 实体（entity）当前是否因控制行为而被禁用。
---@field entity LuaEntity (只读) 此控制行为所属的实体（entity）。
---@field help string 此对象支持的所有方法和属性。
---@field logistic_condition table 物流（logistic）条件。 注意： condition 可以设置为 nil 以清除物流条件。 示例 当其所连接的物流（logistics）网络拥有超过 4 个链信号（chain signal）时，让实体（entity）处于激活状态（例如让灯亮起）： a_behavior.logistic_condition = {condition={comparator=">", first_signal={type="item", name="rail-chain-signal"}, constant=4}}
---@field type defines.control_behavior.type (只读) 此控制行为的具体类型。
---@field use_colors boolean 如果灯应从电路（circuit）网络信号中设置颜色，则为 true。
---@field valid boolean (只读) 此对象是否有效？
LuaLampControlBehavior = {}

--- 参数
--- wire :: defines.wire_type：连接到该实体（entity）的网络的电线（wire）颜色。
--- circuit_connector :: defines.circuit_connector_id（可选）：要获取其电路（circuit）网络的连接器。对于具有多个电路网络连接器的实体（entity），必须指定。
--- 返回值
--- 电路（circuit）网络或 nil。
---@return LuaCircuitNetwork result
---@param circuit_connector defines.circuit_connector_id? 要获取其电路网络的连接器。
对于拥有多个电路网络连接器的实体，必须指定此项。
---@param wire defines.wire_type 连接到此实体的网络的导线颜色。
function LuaLampControlBehavior:get_circuit_network(circuit_connector, wire) end

--- 特定 LuaEntity 的物流（logistic）单元。"物流单元（Logistic Cell）"是通常被视为"机器人港口（Roboport）"所使用的设置和属性的名称。然而，物流单元不必依附于机器人港口实体（entity）（角色（character）拥有一个用于个人机器人港口的物流单元）。
---@class LuaLogisticCell
---@field charge_approach_distance number (只读) 机器人（robot）等待充电时悬停的半径。
---@field charging_robot_count integer (只读) 当前正在充电的机器人（robot）数量。
---@field charging_robots LuaEntity[] (只读) 当前正在充电的机器人（robot）。
---@field construction_radius number (只读) 此单元的建造（construction）半径。
---@field help string 此对象支持的所有方法和属性。
---@field logistic_network LuaLogisticNetwork (只读) 拥有此单元的物流（logistic）网络；否则为 nil。
---@field logistic_radius number (只读) 此单元的物流（logistic）半径。
---@field logistics_connection_distance number (只读) 此单元的物流（logistic）连接距离。
---@field mobile boolean (只读) 如果这是移动（mobile）单元，则为 true。在原版（vanilla）中，只有角色（character）的个人机器人港口（roboport）创建的物流（logistic）单元是移动的。
---@field neighbours LuaLogisticCell[] (只读) 相邻的单元。
---@field owner LuaEntity (只读) 此单元的所有者。
---@field stationed_construction_robot_count integer (只读) 此单元中驻扎的建造（construction）机器人（robot）数量。
---@field stationed_logistic_robot_count integer (只读) 此单元中驻扎的物流（logistic）机器人（robot）数量。
---@field to_charge_robot_count integer (只读) 等待充电的机器人（robot）数量。
---@field to_charge_robots LuaEntity[] (只读) 等待充电的机器人（robot）。
---@field transmitting boolean (只读) 如果此单元处于激活状态，则为 true。
---@field valid boolean (只读) 此对象是否有效？
LuaLogisticCell = {}

--- 给定的位置是否在此单元的建造（construction）范围内？
--- 参数
--- position :: Position
---@return boolean ok
---@param position table
function LuaLogisticCell:is_in_construction_range(position) end

--- 给定的位置是否在此单元的物流（logistic）范围内？
--- 参数
--- position :: Position
---@return boolean ok
---@param position table
function LuaLogisticCell:is_in_logistic_range(position) end

--- 两个单元是否为邻居？
--- 参数
--- other :: LuaLogisticCell
---@return boolean ok
---@param other LuaLogisticCell
function LuaLogisticCell:is_neighbour_with(other) end

--- 物流（logistic）箱子（chest）的控制行为。
---@class LuaLogisticContainerControlBehavior
---@field circuit_mode_of_operation defines.control_behavior.logistic_container.circuit_mode_of_operation 物流（logistic）容器的电路（circuit）工作模式。
---@field entity LuaEntity (只读) 此控制行为所属的实体（entity）。
---@field help string 此对象支持的所有方法和属性。
---@field type defines.control_behavior.type (只读) 此控制行为的具体类型。
---@field valid boolean (只读) 此对象是否有效？
LuaLogisticContainerControlBehavior = {}

--- 参数
--- wire :: defines.wire_type：连接到该实体（entity）的网络的电线（wire）颜色。
--- circuit_connector :: defines.circuit_connector_id（可选）：要获取其电路（circuit）网络的连接器。对于具有多个电路网络连接器的实体（entity），必须指定。
--- 返回值
--- 电路（circuit）网络或 nil。
---@return LuaCircuitNetwork result
---@param circuit_connector defines.circuit_connector_id? 要获取其电路网络的连接器。
对于拥有多个电路网络连接器的实体，必须指定此项。
---@param wire defines.wire_type 连接到此实体的网络的导线颜色。
function LuaLogisticContainerControlBehavior:get_circuit_network(circuit_connector, wire) end

--- 给定地表（surface）上给定势力（force）的单一物流（logistic）网络。
---@class LuaLogisticNetwork
---@field active_provider_points LuaLogisticPoint[] (只读) 此网络中所有主动供应点（active provider point）。
---@field all_construction_robots integer (只读) 网络中建造（construction）机器人（robot）的总数（空闲和激活的 + 机器人港口（roboport）中的）。
---@field all_logistic_robots integer (只读) 网络中物流（logistic）机器人（robot）的总数（空闲和激活的 + 机器人港口（roboport）中的）。
---@field available_construction_robots integer (只读) 可用于执行任务的建造（construction）机器人（robot）数量。
---@field available_logistic_robots integer (只读) 可用于执行任务的物流（logistic）机器人（robot）数量。
---@field cells LuaLogisticCell[] (只读) 此网络中的所有物流（logistic）单元。
---@field construction_robots LuaEntity[] (只读) 此物流（logistic）网络中的所有建造（construction）机器人（robot）。
---@field empty_provider_points LuaLogisticPoint[] (只读) 此网络中所有拥有空供应点（provider point）的事物。
---@field empty_providers LuaEntity[] (只读) 此网络中所有拥有空物流（logistic）供应点（provider point）的实体（entity）。
---@field force LuaForce (只读) 此物流（logistic）网络所属的势力（force）。
---@field help string 此对象支持的所有方法和属性。
---@field logistic_members LuaEntity[] (只读) 此网络中拥有物流（logistic）点的所有其他实体（entity）（主要是机械臂（inserter））。
---@field logistic_robots LuaEntity[] (只读) 此物流（logistic）网络中的所有物流（logistic）机器人（robot）。
---@field passive_provider_points LuaLogisticPoint[] (只读) 此网络中所有被动供应点（passive provider point）。
---@field provider_points LuaLogisticPoint[] (只读) 此网络中所有拥有供应点（provider point）的事物。
---@field providers LuaEntity[] (只读) 此网络中所有拥有物流（logistic）供应点（provider point）的实体（entity）。
---@field requester_points LuaLogisticPoint[] (只读) 此网络中所有拥有请求点（requester point）的事物。
---@field requesters LuaEntity[] (只读) 此网络中所有拥有物流（logistic）请求点（requester point）的实体（entity）。
---@field robot_limit integer (只读) 网络可以使用的机器人（robot）最大数量。目前仅用于个人机器人港口（roboport）。
---@field robots LuaEntity[] (只读) 此物流（logistic）网络中的所有机器人（robot）。
---@field storage_points LuaLogisticPoint[] (只读) 此网络中所有拥有存储点（storage point）的事物。
---@field storages LuaEntity[] (只读) 此网络中所有拥有物流（logistic）存储点（storage point）的实体（entity）。
---@field valid boolean (只读) 此对象是否有效？
LuaLogisticNetwork = {}

--- 查找最接近给定位置的物流（logistic）单元。
--- 参数
--- position :: Position
--- 返回值
--- 如果未找到单元，则可能为
--- nil。
---@return LuaLogisticCell logisticCell
---@param position table
function LuaLogisticNetwork:find_cell_closest_to(position) end

--- 获取整个物流（logistic）网络的物品数量。
--- 返回值
--- 一个将物品原型（prototype）名映射到网络中可用数量的映射。
--- 另请参阅 LuaInventory::get_contents
---@return table<string, integer> count
function LuaLogisticNetwork:get_contents(...) end

--- 统计网络中指定或所有物品（或指定成员）的数量。
--- 参数
--- item :: string（可选）：要计数的物品名。如果未指定，则给出网络中所有物品的数量。
--- member :: string（可选）：要检查的物流（logistic）成员，必须是
--- "storage"
--- 或
--- "providers"
--- 。如果未指定，则给出整个网络中的数量。
---@return integer count
---@param item string? 要计数的物品名称。如果未给出，则统计网络中所有物品的数量。
---@param member string? 要检查的物流成员，必须为 "storage" 或 "providers"。如果未给出，则统计整个网络中的数量。
function LuaLogisticNetwork:get_item_count(item, member) end

--- 将物品插入物流（logistic）网络。这实际上会将物品插入到某些物流（logistic）箱子（chest）中。
--- 参数
--- item :: ItemStackSpecification：要插入的内容。
--- members :: string（可选）：要将物品插入到的物流（logistic）成员。必须是
--- "storage"
--- 、
--- "storage-empty"
--- （完全空的存储箱（storage chest））、
--- "storage-empty-slot"
--- （有空槽位的存储箱（storage chest））或
--- "requester"
--- 。如果未指定，则按常规顺序将物品插入物流（logistic）网络。
--- 返回值
--- 实际插入的物品数量。
---@return integer count
---@param item table 要插入的物品。
---@param members string? 要将物品插入到哪些物流成员中。必须为 "storage"、"storage-empty"（完全为空的储物箱）、"storage-empty-slot"（有空槽位的储物箱）或 "requester"。如果未指定，则按通常顺序将物品插入物流网络。
function LuaLogisticNetwork:insert(item, members) end

--- 从物流（logistic）网络中移除物品。这实际上会从某些物流（logistic）箱子（chest）中移除物品。
--- 参数
--- item :: ItemStackSpecification：要移除的内容。
--- members :: string（可选）：要从哪个物流（logistic）成员中移除。必须是
--- "storage"
--- 、
--- "passive-provider"
--- 、
--- "buffer"
--- 或
--- "active-provider"
--- 。如果未指定，则按常规顺序从网络中移除。
--- 返回值
--- 移除的物品数量。
---@return integer count
---@param item table 要移除的物品。
---@param members string? 要从哪些物流成员中移除。必须为 "storage"、"passive-provider"、"buffer" 或 "active-provider"。如果未指定，则按通常顺序从网络中移除。
function LuaLogisticNetwork:remove_item(item, members) end

--- 查找一个用于投放特定物品堆叠的物流（logistic）点。
--- 参数
--- 包含以下字段的表：
--- stack :: ItemStackSpecification：要选择的物品名。
--- members :: string（可选）：如果给定，将仅从特定类型的成员中查找。必须是
--- "storage"
--- 、
--- "storage-empty"
--- 、
--- "storage-empty-slot"
--- 或
--- "requester"
--- 。如果未指定，则按常规优先级选择。
--- 返回值
--- 如果未找到点，则可能为
--- nil。
---@return LuaLogisticPoint count
---@param stack table? stack :: ItemStackSpecification: 要选择的物品名称。  
members :: string (可选): 给出时，将只从特定类型的成员中查找。必须为 "storage"、"storage-empty"、"storage-empty-slot" 或 "requester"。如果未指定，则按正常优先级选择。
function LuaLogisticNetwork:select_drop_point(stack) end

--- 查找具有此物品 ID 的"最佳"物流（logistic）点，可以从给定位置或给定箱子（chest）类型中查找。
--- 参数
--- 包含以下字段的表：
--- name :: string：要选择的物品名。
--- position :: Position（可选）：如果给定，将从该位置查找"最佳"存储点。
--- include_buffers :: boolean（可选）：是否考虑缓冲箱（buffer chest）。默认为 false。仅在按位置选择时考虑。
--- members :: string（可选）：如果给定，将仅从特定类型的成员中查找。必须是
--- "storage"
--- 、
--- "passive-provider"
--- 、
--- "buffer"
--- 或
--- "active-provider"
--- 。如果未指定，则按常规优先级选择。如果指定了位置，则不进行考虑。
--- 返回值
--- 如果未找到点，则可能为
--- nil。
---@return LuaLogisticPoint count
---@param name string? name :: string: 要选择的物品名称。  
position :: Position (可选): 给出时，将从该位置查找“最佳”储物点。  
include_buffers :: boolean (可选): 是否考虑缓冲箱（buffer chests）。默认为 false。仅在指定 position 时考虑。  
members :: string (可选): 给出时，将只从特定类型的成员中查找。必须为 "storage"、"passive-provider"、"buffer" 或 "active-provider"。如果未指定，则按正常优先级选择。指定 position 时不考虑此参数。
function LuaLogisticNetwork:select_pickup_point(name) end

--- 特定 LuaEntity 的物流（logistic）点。"物流点（Logistic point）"是给定物流（logistic）网络中请求点（requester）、供应点（provider）和存储点（storage point）所使用的设置和属性的名称。这些"点"不必是物流（logistic）容器，但通常就是。另一个可以拥有多个点的实体（entity）是"角色（character）"类型的实体。
---@class LuaLogisticPoint
---@field exact boolean (只读) 此物流（logistic）点是否使用精确模式。在精确模式下，机器人（robot）永远不会超额交付请求。
---@field filters table[] (只读) 此物流（logistic）点的物流（logistic）过滤器；如果不使用物流过滤器，则为 nil。 注意： 返回的数组始终为每个过滤器都有一个条目，并且不为 nil 时会按顺序索引。
---@field force LuaForce (只读) 此物流（logistic）点的势力（force）。 注意： 它始终与 LuaLogisticPoint::owner 的势力（force）相同。
---@field help string 此对象支持的所有方法和属性。
---@field logistic_member_index integer (只读) 此物流（logistic）点的物流成员索引。
---@field logistic_network LuaLogisticNetwork (只读)
---@field mode defines.logistic_mode (只读) 物流（logistic）模式。
---@field owner LuaEntity (只读) 此 LuaLogisticPoint 的 LuaEntity 所有者。
---@field targeted_items_deliver table<string, integer> (只读) 机器人（robot）计划投放到此物流（logistic）点的物品。
---@field targeted_items_pickup table<string, integer> (只读) 机器人（robot）计划从此物流（logistic）点取走的物品。
---@field valid boolean (只读) 此对象是否有效？
LuaLogisticPoint = {}

--- 采矿（mining）钻机（drill）的控制行为。
---@class LuaMiningDrillControlBehavior
---@field circuit_condition table 电路（circuit）条件。 注意： condition 可以设置为 nil 以清除电路条件。 示例 当实体（entity）接收到超过 4 个链信号（chain signal）的电路信号时，让其实体处于激活状态（例如让灯亮起）： a_behavior.circuit_condition = {condition={comparator=">", first_signal={type="item", name="rail-chain-signal"}, constant=4}}
---@field circuit_enable_disable boolean 如果此钻机（drill）使用物流（logistics）或电路（circuit）条件来启用或禁用，则为 true。
---@field circuit_read_resources boolean 如果此钻机（drill）应将矿场中的资源发送到电路（circuit）网络，则为 true。发送哪些资源取决于 LuaMiningDrillControlBehavior::resource_read_mode
---@field connect_to_logistic_network boolean 如果此设备应连接到物流（logistic）网络，则为 true。
---@field disabled boolean (只读) 实体（entity）当前是否因控制行为而被禁用。
---@field entity LuaEntity (只读) 此控制行为所属的实体（entity）。
---@field help string 此对象支持的所有方法和属性。
---@field logistic_condition table 物流（logistic）条件。 注意： condition 可以设置为 nil 以清除物流条件。 示例 当其所连接的物流（logistics）网络拥有超过 4 个链信号（chain signal）时，让实体（entity）处于激活状态（例如让灯亮起）： a_behavior.logistic_condition = {condition={comparator=">", first_signal={type="item", name="rail-chain-signal"}, constant=4}}
---@field resource_read_mode defines.control_behavior.mining_drill.resource_read_mode 采矿（mining）钻机（drill）是只将其区域内的资源发送到电路（circuit）网络，还是将其所在的整个矿场的资源都发送到电路（circuit）网络。
---@field resource_read_targets LuaEntity[] (只读) 采矿（mining）钻机（drill）将向电路（circuit）网络发送其信息的资源实体（entity）；如果没有，则为空数组。
---@field type defines.control_behavior.type (只读) 此控制行为的具体类型。
---@field valid boolean (只读) 此对象是否有效？
LuaMiningDrillControlBehavior = {}

--- 参数
--- wire :: defines.wire_type：连接到该实体（entity）的网络的电线（wire）颜色。
--- circuit_connector :: defines.circuit_connector_id（可选）：要获取其电路（circuit）网络的连接器。对于具有多个电路网络连接器的实体（entity），必须指定。
--- 返回值
--- 电路（circuit）网络或 nil。
---@return LuaCircuitNetwork result
---@param circuit_connector defines.circuit_connector_id? 要获取其电路网络的连接器。
对于拥有多个电路网络连接器的实体，必须指定此项。
---@param wire defines.wire_type 连接到此实体的网络的导线颜色。
function LuaMiningDrillControlBehavior:get_circuit_network(circuit_connector, wire) end

--- mod 设置（setting）的原型（prototype）。
---@class LuaModSettingPrototype
---@field allow_blank boolean (只读) 此字符串（string）设置是否允许空白值；如果不是字符串设置，则为 nil。
---@field allowed_values string | integer[] | number[][] (只读) 此设置的允许值；如果此设置不使用固定的值集合，则为 nil。
---@field auto_trim boolean (只读) 此字符串（string）设置是否自动修剪值；如果不是字符串设置，则为 nil。
---@field default_value boolean | number | integer | string (只读) 此设置的默认值。
---@field help string 此对象支持的所有方法和属性。
---@field localised_description table (只读)
---@field localised_name table (只读)
---@field maximum_value number | integer (只读) 此设置的最大值；如果此设置类型不支持最大值，则为 nil。
---@field minimum_value number | integer (只读) 此设置的最小值；如果此设置类型不支持最小值，则为 nil。
---@field mod string (只读) 拥有此设置的 mod。
---@field name string (只读) 此原型（prototype）的名称。
---@field order string (只读) 此原型（prototype）的排序字符串。
---@field setting_type string (只读)
---@field valid boolean (只读) 此对象是否有效？
LuaModSettingPrototype = {}

--- 命名噪声表达式的原型。
---@class LuaNamedNoiseExpression
---@field expression table (只读) 表达式本身。
---@field help string 此对象支持的所有方法和属性。
---@field intended_property string (只读) 此表达式旨在为其提供值的属性的名称（如果有的话）。
---@field localised_description table (只读)
---@field localised_name table (只读)
---@field name string (只读) 此原型的名称。
---@field order string (只读) 此原型的排序字符串。
---@field valid boolean (只读) 此对象是否有效？
LuaNamedNoiseExpression = {}

--- 噪声层的原型。
---@class LuaNoiseLayerPrototype
---@field help string 此对象支持的所有方法和属性。
---@field localised_description table (只读)
---@field localised_name table (只读)
---@field name string (只读) 此原型的名称。
---@field order string (只读) 此原型的排序字符串。
---@field valid boolean (只读) 此对象是否有效？
LuaNoiseLayerPrototype = {}

--- 一个权限组，定义该组内玩家被允许做什么。
---@class LuaPermissionGroup
---@field group_id integer (只读) 该组的 ID。
---@field help string 此对象支持的所有方法和属性。
---@field name string 此组的名称 注意： 设置为 nil 或空字符串会将名称设置为默认值。
---@field players LuaPlayer[] (只读) 此组中的玩家
---@field valid boolean (只读) 此对象是否有效？
LuaPermissionGroup = {}

--- 将给定的玩家添加到此组
--- 参数
--- player :: PlayerSpecification
--- 返回值
--- 如果该玩家已被添加。
---@return boolean ok
---@param player table
function LuaPermissionGroup:add_player(player) end

--- 此组是否允许给定的动作
--- 参数
--- action: defines.input_action 值。
---@return boolean ok
---@param action table defines.input_action 的值。
function LuaPermissionGroup:allows_action(action) end

--- 销毁此组
--- 返回值
--- 如果该组已被销毁。
---@return boolean ok
function LuaPermissionGroup:destroy(...) end

--- 将给定的玩家从此组中移除
--- 参数
--- player :: PlayerSpecification
--- 返回值
--- 如果该玩家已被移除。
---@return boolean ok
---@param player table
function LuaPermissionGroup:remove_player(player) end

--- 设置玩家是否被允许执行给定的动作
--- 参数
--- action: defines.input_action 值。
--- 返回值
--- 如果该值已应用。
---@return boolean ok
---@param action table defines.input_action 的值。
---@param undefined any
function LuaPermissionGroup:set_allows_action(action, undefined) end

--- 所有权限组。
---@class LuaPermissionGroups
---@field groups LuaPermissionGroup[] (只读) 所有权限组。
---@field help string 此对象支持的所有方法和属性。
---@field valid boolean (只读) 此对象是否有效？
LuaPermissionGroups = {}

--- 创建一个新的权限组
--- 参数
--- name :: string (可选)
--- 注意： 如果调用玩家没有创建组的权限，则可能返回 nil。
---@return LuaPermissionGroup permissionGroup
---@param name string?
function LuaPermissionGroups:create_group(name) end

--- 获取具有给定名称或组 ID 的权限组；如果没有匹配的组，则返回
--- nil
--- 参数
--- group :: string 或 uint
---@return LuaPermissionGroup permissionGroup
---@param group string | integer
function LuaPermissionGroups:get_group(group) end

--- 游戏中的一名玩家。请注意，玩家可能有也可能没有角色（character），角色就是那个在世界中跑来跑去做事的小人儿的
--- LuaEntity。
---@class LuaPlayer
---@field admin boolean true 表示该玩家是管理员 注意： 当你不是管理员时，尝试从控制台更改玩家的管理员状态不会产生任何效果。
---@field afk_time integer (只读) 自该玩家上次操作以来经过的 tick 数
---@field auto_trash_filters table<string, integer> 自动垃圾桶过滤器（auto-trash filters）。键是物品原型名称，值是槽位数值。 注意： 当在 LuaPlayer 上调用时，它必须与一个角色相关联（参见 LuaPlayer::character）。 示例 这将设置自动垃圾桶槽位，使玩家仓库中最多保留 20 个铁板和 42 个铜线 game.player.auto_trash_filters聽=聽{["iron-plate"]聽=聽20,聽["copper-cable"]聽=聽42}
---@field blueprint_to_setup LuaItemStack (只读) 包含待设置蓝图（blueprint）的物品堆叠
---@field build_distance integer (只读) 该角色的建造距离；当不是角色或未连接到角色的玩家时，为 uint 最大值
---@field character LuaEntity 附加到此玩家的角色；如果没有角色则为 nil 。 注意： 当玩家断开连接时也会返回 nil （参见 LuaPlayer::connected）。
---@field character_additional_mining_categories string[] 注意： 当在 LuaPlayer 上调用时，它必须与一个角色相关联（参见 LuaPlayer::character）。
---@field character_build_distance_bonus integer 注意： 当在 LuaPlayer 上调用时，它必须与一个角色相关联（参见 LuaPlayer::character）。
---@field character_crafting_speed_modifier number 注意： 当在 LuaPlayer 上调用时，它必须与一个角色相关联（参见 LuaPlayer::character）。
---@field character_health_bonus number 注意： 当在 LuaPlayer 上调用时，它必须与一个角色相关联（参见 LuaPlayer::character）。
---@field character_inventory_slots_bonus integer 注意： 当在 LuaPlayer 上调用时，它必须与一个角色相关联（参见 LuaPlayer::character）。
---@field character_item_drop_distance_bonus integer 注意： 当在 LuaPlayer 上调用时，它必须与一个角色相关联（参见 LuaPlayer::character）。
---@field character_item_pickup_distance_bonus integer 注意： 当在 LuaPlayer 上调用时，它必须与一个角色相关联（参见 LuaPlayer::character）。
---@field character_logistic_slot_count_bonus integer 注意： 当在 LuaPlayer 上调用时，它必须与一个角色相关联（参见 LuaPlayer::character）。
---@field character_loot_pickup_distance_bonus integer 注意： 当在 LuaPlayer 上调用时，它必须与一个角色相关联（参见 LuaPlayer::character）。
---@field character_maximum_following_robot_count_bonus integer 注意： 当在 LuaPlayer 上调用时，它必须与一个角色相关联（参见 LuaPlayer::character）。
---@field character_mining_speed_modifier number 注意： 当在 LuaPlayer 上调用时，它必须与一个角色相关联（参见 LuaPlayer::character）。
---@field character_reach_distance_bonus integer 注意： 当在 LuaPlayer 上调用时，它必须与一个角色相关联（参见 LuaPlayer::character）。
---@field character_resource_reach_distance_bonus integer 注意： 当在 LuaPlayer 上调用时，它必须与一个角色相关联（参见 LuaPlayer::character）。
---@field character_running_speed number (只读) 获取该角色当前的移动速度，包括外骨骼、地块、粘液（sticker）和射击状态带来的效果
---@field character_running_speed_modifier number 注意： 当在 LuaPlayer 上调用时，它必须与一个角色相关联（参见 LuaPlayer::character）。
---@field character_trash_slot_count_bonus integer 注意： 当在 LuaPlayer 上调用时，它必须与一个角色相关联（参见 LuaPlayer::character）。
---@field chat_color table 该玩家在游戏中说话时使用的颜色。
---@field cheat_mode boolean 当为 true 时，手工制作免费且即时完成
---@field color table 与该玩家关联的颜色。它将用于为玩家的角色以及 建筑和载具着色。
---@field connected boolean (只读) 如果该玩家当前已连接到游戏，则为 true 。
---@field controller_type defines.controllers (只读)
---@field crafting_queue table[] (只读) 获取当前制作队列中的条目。每个 CraftingQueueItem 都是一个表： index :: uint: 制作队列索引 recipe :: string: 配方。 count :: uint: 正在制作的数量。
---@field crafting_queue_size integer (只读) 制作队列的大小。
---@field cursor_ghost table 玩家光标中的虚影（ghost）原型 注意： 读取时，它将是一个 LuaItemPrototype。 注意： 光标堆叠中的物品优先于光标虚影。
---@field cursor_stack LuaItemStack (只读) 玩家的光标堆叠。
---@field display_resolution table (只读) 该玩家的显示分辨率
---@field display_scale number (只读) 该玩家的显示缩放比例
---@field driving boolean 如果玩家在载具中，则为 true 。写入此属性可使玩家进入或离开 载具。
---@field drop_item_distance integer (只读) 该角色的物品丢弃距离；当不是角色或未连接到角色的玩家时，为 uint 最大值
---@field entity_copy_source LuaEntity (只读) 实体设置复制-粘贴时使用的源实体；如果当前没有源实体，则为 nil 。
---@field following_robots LuaEntity[] (只读) 当前跟随角色的战斗机器人 注意： 当在 LuaPlayer 上调用时，它必须与一个角色相关联（参见 LuaPlayer::character）。
---@field force table 此实体的势力。读取时总会得到一个 LuaForce，但可以 为此属性赋 string 或 LuaForce 来更改势力。
---@field game_view_settings table 玩家的游戏视图设置。
---@field gui LuaGui (只读)
---@field help string 此对象支持的所有方法和属性。
---@field in_combat boolean (只读) 此角色实体是否处于战斗中
---@field index integer (只读) 此玩家在 LuaGameScript::players 中的索引。
---@field item_pickup_distance number (只读) 该角色的物品拾取距离；当不是角色或未连接到角色的玩家时，为 double 最大值
---@field last_online integer (只读) 该玩家最后一次在线时的 tick
---@field loot_pickup_distance number (只读) 该角色的战利品拾取距离；当不是角色或未连接到角色的玩家时，为 double 最大值
---@field map_view_settings table (只写) 玩家的地图视图设置。要写入此属性，请使用包含应更改字段的表
---@field minimap_enabled boolean 如果小地图可见，则为 true 。
---@field mining_state table 当前开采状态 它是一个包含两个字段的表： mining :: boolean: 玩家是否在开采 position :: Position (可选): 玩家正在开采哪些地块；仅当玩家开采地块（光标中持有地块）时使用。 注意： 当玩家不在开采地块时，玩家会开采当前选中的任何实体。参见 LuaControl::selected 和 LuaControl::update_selected_entity。
---@field mod_settings any (只读) 注意： 如果在操作过程中此玩家变为无效，它可能会失效。
---@field name string 该玩家的用户名。
---@field online_time integer (只读) 该玩家在此存档中游玩所花费的 tick 数（所有会话合计）
---@field opened LuaEntity | LuaItemStack | LuaEquipment | LuaEquipmentGrid | LuaPlayer | LuaGuiElement | defines.gui_type 玩家当前打开的界面目标；如果没有则为 nil 注意： 写入支持任何类型。读取将返回实体、装备、元素或 nil。
---@field opened_gui_type defines.gui_type (只读) 返回 defines.gui_type 或 nil 。
---@field opened_self boolean (只读) 如果玩家打开了自己的界面，则为 true 。即打开了角色或上帝控制器界面。
---@field permission_group LuaPermissionGroup 此玩家所属的权限组；如果不属于任何组，则为 nil
---@field picking_state boolean 当前拾取物品状态
---@field position table (只读) 实体的当前位置。
---@field reach_distance integer (只读) 该角色的触及距离；当不是角色或未连接到角色的玩家时，为 uint 最大值
---@field render_mode defines.render_mode (只读) 玩家的渲染模式，如地图或缩放到世界 渲染模式可以使用 LuaPlayer::open_map、LuaPlayer::zoom_to_world 和 LuaPlayer::close_map 设置
---@field repair_state table 当前修理状态 它是一个包含两个字段的表： repairing :: boolean: 当前状态 position :: Position: 正在被修理的位置
---@field resource_reach_distance number (只读) 该角色的资源触及距离；当不是角色或未连接到角色的玩家时，为 double 最大值
---@field riding_state table 此车或此玩家所乘坐载具的当前乘坐状态
---@field selected LuaEntity 当前选中的实体；如果没有则为 nil 。赋一个实体将选中它（如果可选中），否则清除选择。
---@field shooting_state table 当前射击状态 它是一个包含两个字段的表： state :: defines.shooting: 当前状态 position :: Position: 正在被射击的位置
---@field spectator boolean 如果为 true ，缩放到世界的噪声效果将被禁用，环境音效将基于 缩放到世界的视图而非玩家角色的位置。
---@field surface LuaSurface (只读) 此实体当前所在的地表。
---@field tag string 显示在聊天和地图中玩家名称之后的标签。
---@field ticks_to_respawn integer 此玩家重生前剩余的 tick 数；如果未在等待重生，则为 nil 注意： 设置为 nil 可立即重生该玩家。 注意： 设置为任何正值会触发此玩家的重生状态。
---@field valid boolean (只读) 此对象是否有效？
---@field vehicle LuaEntity (只读) 玩家当前乘坐的载具；如果没有则为 nil 。
---@field walking_state table 当前行走状态 它是一个包含两个字段的表： walking :: boolean: 如果为 false ，则玩家当前未在行走；否则正在走向某处 direction :: defines.direction: 玩家行走的方向 示例 让玩家向北走。注意，像这样的一次性动作只会让玩家走一个 tick game.player.walking_state聽=聽{walking聽=聽true,聽direction聽=聽defines.direction.north}
---@field zoom number (只写) 玩家的缩放级别。
LuaPlayer = {}

--- 为给定实体以给定的警报类型向此玩家添加警报
--- 参数
--- entity :: LuaEntity
--- type :: defines.alert_type
---@param entity LuaEntity
---@param type defines.alert_type
function LuaPlayer:add_alert(entity, type) end

--- 向此玩家添加一条自定义警报
--- 参数
--- entity :: LuaEntity
--- icon :: SignalID
--- message :: LocalisedString
--- show_on_map :: boolean
---@param entity LuaEntity
---@param icon table
---@param message table
---@param show_on_map boolean
function LuaPlayer:add_custom_alert(entity, icon, message, show_on_map) end

--- 将一个角色与此玩家关联
--- 参数
--- character :: LuaEntity: 角色实体。
--- 注意： 该角色不能连接到任何控制器。
--- 注意： 如果此玩家当前已断开连接（参见 LuaPlayer::connected），该角色将立即"下线"。
--- 注意： 更多信息请参见 LuaPlayer::get_associated_characters。
---@param character LuaEntity 角色实体。
function LuaPlayer:associate_character(character) end

--- 开始按给定数量制作给定的配方
--- 参数
--- count :: uint: 要制作的数量。
--- recipe :: string 或 LuaRecipe: 要制作的配方。
--- silent :: boolean (可选): 如果为 false 且配方无法按请求的次数制作，则跳过打印失败信息。
--- 返回值
--- 实际开始制作的数量。
---@return integer count
---@param count integer? 要制造的数量。
recipe :: [string] 或 [LuaRecipe]：要制造的配方。
silent :: [boolean]（可选）：如果为 false，且配方无法按请求的次数制造，则跳过失败信息的打印。
function LuaPlayer:begin_crafting(count) end

--- 在玩家所在的地表上建造光标中的任意内容
--- 参数
--- 包含以下字段的表：
--- position :: Position: 实体将被放置的位置
--- direction :: defines.direction (可选): 实体将被放置的方向
--- alt :: boolean (可选): 是否使用 alt 建造而非普通建造。默认为普通建造。
--- terrain_building_size :: uint (可选): 若在建造地形，则为建造地形的大小。默认为 2。
--- skip_fog_of_war :: boolean (可选): 是否跳过被战争迷雾覆盖的区块。
--- 注意： 建造的任何东西都会触发正常的玩家建造事件。
--- 注意： 光标堆叠会自动减少，就像玩家正常建造一样。
---@param position table? position :: Position：实体将被放置的位置
direction :: defines.direction（可选）：实体将被放置的方向
alt :: boolean（可选）：是否使用 alt 建造模式而非普通建造模式。默认为普通模式
terrain_building_size :: uint（可选）：建造地形时地形的大小。默认为 2
skip_fog_of_war :: boolean（可选）：是否跳过被战争迷雾覆盖的区块。
function LuaPlayer:build_from_cursor(position) end

--- 检查此玩家是否能在其所在的地表上建造光标中的任意内容
--- 参数
--- 包含以下字段的表：
--- position :: Position: 实体将被放置的位置
--- direction :: defines.direction (可选): 实体将被放置的方向
--- alt :: boolean (可选): 是否使用 alt 建造而非普通建造。默认为普通建造。
--- terrain_building_size :: uint (可选): 若在建造地形，则为建造地形的大小。默认为 2。
--- skip_fog_of_war :: boolean (可选): 是否跳过被战争迷雾覆盖的区块。
---@return boolean ok
---@param position table? position :: Position：实体将被放置的位置
direction :: defines.direction（可选）：实体将被放置的方向
alt :: boolean（可选）：是否使用 alt 建造模式而非普通建造模式。默认为普通模式
terrain_building_size :: uint（可选）：建造地形时地形的大小。默认为 2
skip_fog_of_war :: boolean（可选）：是否跳过被战争迷雾覆盖的区块。
function LuaPlayer:can_build_from_cursor(position) end

--- 能否插入至少部分物品？
--- 参数
--- items :: ItemStackSpecification: 将被插入的物品。
--- 返回值
--- 如果给定物品中至少有一部分可以插入此仓库，则返回
--- true
--- 。
---@return boolean ok
---@param items table 将要插入的物品。
function LuaPlayer:can_insert(items) end

--- 检查此玩家能否在其所在的地表上的给定位置建造给定实体
--- 参数
--- 包含以下字段的表：
--- name :: string: 要检查的实体的名称
--- position :: Position: 实体将被放置的位置
--- direction :: defines.direction (可选): 实体将被放置的方向
---@return boolean ok
---@param name string? name :: string：要检查的实体名称
position :: Position：实体将被放置的位置
direction :: defines.direction（可选）：实体将被放置的方向
function LuaPlayer:can_place_entity(name) end

--- 给定的实体能否被打开或访问？
--- 参数
--- entity :: LuaEntity
---@return boolean ok
---@param entity LuaEntity
function LuaPlayer:can_reach_entity(entity) end

--- 取消在给定制作队列索引处制作给定数量
--- 参数
--- options: :
--- index :: uint: 制作队列索引。
--- count :: uint: 要取消制作的数量。
---@param options integer 制造队列（crafting queue）索引。
count :: [uint]：要取消制造的数量。
function LuaPlayer:cancel_crafting(options) end

--- 对该玩家调用"清理光标"动作，就像用户按下了该键
--- 返回值
--- 光标现在是否为空。
---@return boolean ok
function LuaPlayer:clean_cursor(...) end

--- 清空聊天控制台。
function LuaPlayer:clear_console(...) end

--- 移除由
--- set_gui_arrow
--- 创建的箭头。
function LuaPlayer:clear_gui_arrow(...) end

--- 从此实体中移除所有物品。
function LuaPlayer:clear_items_inside(...) end

--- 取消选择任何已选中的实体。
function LuaPlayer:clear_selected_entity(...) end

--- 排队请求从地图或缩放到世界视图切换到普通游戏视图
--- 渲染模式更改请求会在渲染下一帧之前处理。
function LuaPlayer:close_map(...) end

--- 创建角色实体并将其附加到此玩家
--- 参数
--- character :: string (可选): 要创建的角色，否则使用默认角色。
--- 返回值
--- 角色是否已创建。
--- 注意： 该玩家不能已连接角色，且必须在线（参见 LuaPlayer::connected）。
---@return boolean ok
---@param character string? 要创建的角色；否则使用默认角色。
function LuaPlayer:create_character(character) end

--- 生成仅对此玩家可见的飘浮文字
--- 参数
--- 包含以下字段的表：
--- text :: LocalisedString
--- position :: Position
--- color :: Color (可选)
--- time_to_live :: uint (可选)
--- speed :: double (可选): 每秒移动距离
--- 注意： 本地飘浮文字不会被保存，这意味着它在存档/读档后会消失。
---@param text table? text :: LocalisedString
position :: Position
color :: Color（可选）
time_to_live :: uint（可选）
speed :: double（可选）：每秒移动量
function LuaPlayer:create_local_flying_text(text) end

--- 禁用给定警报类别的警报
--- 参数
--- alert_type :: defines.alert_type
--- 返回值
--- 警报类型是否已被禁用（如果已被禁用则返回 false）。
---@return boolean ok
---@param alert_type defines.alert_type
function LuaPlayer:disable_alert(alert_type) end

--- 禁用闪光灯。
function LuaPlayer:disable_flashlight(...) end

--- 禁用配方组。
function LuaPlayer:disable_recipe_groups(...) end

--- 禁用配分子组。
function LuaPlayer:disable_recipe_subgroups(...) end

--- 解除一个角色与此玩家的关联
--- 这在功能上等同于将 LuaEntity::associated_player 设置为
--- nil
--- 参数
--- character :: LuaEntity: 角色实体
--- 注意： 更多信息请参见 LuaPlayer::get_associated_characters。
---@param character LuaEntity 角色实体
function LuaPlayer:disassociate_character(character) end

--- 启用给定警报类别的警报
--- 参数
--- alert_type :: defines.alert_type
--- 返回值
--- 警报类型是否已被启用（如果已被启用则返回 false）。
---@return boolean ok
---@param alert_type defines.alert_type
function LuaPlayer:enable_alert(alert_type) end

--- 启用闪光灯。
function LuaPlayer:enable_flashlight(...) end

--- 启用配方组。
function LuaPlayer:enable_recipe_groups(...) end

--- 启用配分子组。
function LuaPlayer:enable_recipe_subgroups(...) end

--- 退出当前过场动画。如果不在过场动画中则报错。
function LuaPlayer:exit_cutscene(...) end

--- 获取给定屏幕页正在使用哪个快捷栏页面；如果未知则为
--- nil
--- 参数
--- index :: uint: 屏幕页。索引 1 是界面中的顶行。索引可以超出屏幕上可见的栏数，以适应界面配置设置的变化。
---@return integer count
---@param index integer 屏幕页。索引 1 是界面中的顶行。索引可以超出屏幕上可见的快捷栏数量，以适配界面配置设置的更改。
function LuaPlayer:get_active_quick_bar_page(index) end

--- 获取所有匹配给定过滤条件的警报；如果未给定过滤条件，则返回所有警报
--- 返回地表索引到按警报类型索引的警报数组的数组的映射
--- 警报是一个表：
--- target :: LuaEntity (可选)
--- prototype :: LuaEntityPrototype (可选)
--- position :: Position (可选)
--- tick :: uint: 此警报被创建的 tick
--- icon :: SignalID (可选): 自定义警报使用的 SignalID。仅自定义警报存在。
--- message :: LocalisedString (可选): 自定义警报的消息。仅自定义警报存在。
--- 参数
--- 包含以下字段的表：
--- entity :: LuaEntity (可选)
--- prototype :: LuaEntityPrototype (可选)
--- position :: Position (可选)
--- type :: defines.alert_type (可选)
--- surface :: SurfaceSpecification (可选)
---@return table<integer, table<defines.alert_type, table[]>> count
---@param entity LuaEntity? entity :: LuaEntity（可选）
prototype :: LuaEntityPrototype（可选）
position :: Position（可选）
type :: defines.alert_type（可选）
surface :: SurfaceSpecification（可选）
function LuaPlayer:get_alerts(entity) end

--- 与此玩家关联的角色
--- 注意： 当玩家断开连接时，无论是否存在关联角色，该数组始终为空（参见 LuaPlayer::connected）。
--- 注意： 与此玩家关联的角色会在该玩家断开连接时被注销，且不受任何玩家控制。
---@return LuaEntity[] entity
function LuaPlayer:get_associated_characters(...) end

--- 获取可以制作的给定配方的数量
--- 参数
--- recipe :: string 或 LuaRecipe: 配方。
--- 返回值
--- 可以制作的数量。
---@return integer count
---@param recipe string | LuaRecipe 配方。
function LuaPlayer:get_craftable_count(recipe) end

--- 获取当前目标描述，以本地化字符串形式返回。
---@return table result
function LuaPlayer:get_goal_description(...) end

--- 获取属于此实体的仓库。这可以是"主"仓库，也可以是某种辅助仓库，
--- 比如插件槽或物流垃圾桶槽
--- 参数
--- inventory :: defines.inventory
--- 返回值
--- 如果此实体没有给定索引对应的仓库，则返回
--- nil
--- 。
--- 注意： 给定的 defines.inventory 仅对相应的 LuaObject 类型有意义。例如：get_inventory(defines.inventory.character_main) 仅当'this'是玩家角色时才有意义。你可能会得到一个返回值，但如果'this'的类型不是 defines.inventory 所指的类型，那么它几乎可以肯定不是所请求的仓库。
---@return LuaInventory result
---@param inventory defines.inventory
function LuaPlayer:get_inventory(inventory) end

--- 获取此实体中全部或部分物品的数量。
--- 参数
--- item :: string (可选): 要计数的物品的原型名称。如果未指定，则统计所有物品。
---@return integer count
---@param item string? 要计数的物品的原型名称。如果未指定，则统计所有物品。
function LuaPlayer:get_item_count(item) end

--- 如果这是角色或玩家，则获取该角色或玩家的主仓库。
--- 返回值
--- 如果此实体不是角色或玩家，则返回
--- nil
--- 。
---@return LuaInventory result
function LuaPlayer:get_main_inventory(...) end

--- 获取给定槽位的快捷栏过滤器；如果没有则为
--- nil
--- 参数
--- index :: uint: 槽位索引。1 为第一页第一个槽位，2 为第一页第二个槽位，11 为第二页第一个槽位，依此类推。
---@return LuaItemPrototype itemPrototype
---@param index integer 栏位索引。1 表示第一页的第一个栏位，2 表示第一页的第二个栏位，11 表示第二页的第一个栏位，依此类推。
function LuaPlayer:get_quick_bar_slot(index) end

--- 此实体内部是否有任何物品？
---@return boolean ok
function LuaPlayer:has_items_inside(...) end

--- 向此实体插入物品。其工作方式与机械臂插入或 shift 点击相同："最合适的
--- 仓库会被自动选择。
--- 参数
--- items :: ItemStackSpecification: 要插入的物品。
--- 返回值
--- 实际插入的物品数量。
---@return integer count
---@param items table 要插入的物品。
function LuaPlayer:insert(items) end

--- 给定的警报类型当前是否已启用
--- 参数
--- alert_type :: defines.alert_type
---@return boolean ok
---@param alert_type defines.alert_type
function LuaPlayer:is_alert_enabled(alert_type) end

--- 给定的警报类型当前是否已静音
--- 参数
--- alert_type :: defines.alert_type
---@return boolean ok
---@param alert_type defines.alert_type
function LuaPlayer:is_alert_muted(alert_type) end

--- 当为
--- true
--- 时，控制适配器是 LuaPlayer 对象；对于包括带玩家的角色在内的实体，则为
--- false
---@return boolean ok
function LuaPlayer:is_player(...) end

--- 自定义快捷方式当前是否可用
--- 参数
--- prototype_name :: string: 自定义快捷方式的原型名称。
---@return boolean ok
---@param prototype_name string 自定义快捷方式的原型名称。
function LuaPlayer:is_shortcut_available(prototype_name) end

--- 自定义快捷方式当前是否已切换（toggled）
--- 参数
--- prototype_name :: string: 自定义快捷方式的原型名称。
---@return boolean ok
---@param prototype_name string 自定义快捷方式的原型名称。
function LuaPlayer:is_shortcut_toggled(prototype_name) end

--- 跳转到指定的过场动画路径点。仅当玩家正在观看过场动画时有效
--- 参数
--- waypoint_index :: uint
---@param waypoint_index integer
function LuaPlayer:jump_to_cutscene_waypoint(waypoint_index) end

--- 开采给定实体，就像此玩家（或角色）开采它一样
--- 参数
--- entity :: LuaEntity: 要开采的实体
--- force :: boolean (可选): 即使物品无法放入玩家背包，也强制开采该实体。
--- 返回值
--- 开采是否成功。
---@return boolean ok
---@param entity LuaEntity 要开采的实体。
---@param force boolean? 即使物品无法放入玩家（背包）中，也强制开采该实体。
function LuaPlayer:mine_entity(entity, force) end

--- 开采给定地块，就像此玩家（或角色）开采它一样
--- 参数
--- tile :: LuaTile: 要开采的地块。
--- 返回值
--- 开采是否成功。
---@return boolean ok
---@param tile LuaTile 要开采的地块（tile）。
function LuaPlayer:mine_tile(tile) end

--- 静音给定警报类别的警报
--- 参数
--- alert_type :: defines.alert_type
--- 返回值
--- 警报类型是否已被静音（如果已被静音则返回 false）。
---@return boolean ok
---@param alert_type defines.alert_type
function LuaPlayer:mute_alert(alert_type) end

--- 排队请求在指定位置打开地图。如果地图已经打开，该请求将仅设置位置（和缩放）
--- 渲染模式更改请求会在渲染下一帧之前处理
--- 参数
--- position :: Position
--- scale :: double (可选)
---@param position table
---@param scale number?
function LuaPlayer:open_map(position, scale) end

--- 打开科技界面并选择给定的科技
--- 参数
--- technology :: TechnologySpecification (可选): 打开界面后要选择的科技。
---@param technology table? 打开界面（GUI）后要选择的科技。
function LuaPlayer:open_technology_gui(technology) end

--- 对该玩家调用"智能滴管"动作，就像用户按下了该键
--- 参数
--- entity :: string 或 LuaEntity 或 LuaEntityPrototype
--- 返回值
--- 智能滴管是否找到了可放置的东西
---@return boolean ok
---@param entity string | LuaEntity | LuaEntityPrototype
function LuaPlayer:pipette_entity(entity) end

--- 为此玩家播放音效
--- 参数
--- 包含以下字段的表：
--- path :: SoundPath: 要播放的音效
--- position :: Position (可选): 音效应在何处播放。如果未给出，则在'各处'播放。
--- volume_modifier :: double (可选): 必须介于 0 和 1 之间（含端点）。
---@return boolean ok
---@param path table? path :: SoundPath：要播放的声音
position :: Position（可选）：声音播放的位置。若未给出，则在"所有地方"播放。
volume_modifier :: double（可选）：必须介于 0 到 1 之间（含两端）。
function LuaPlayer:play_sound(path) end

--- 将文本打印到聊天控制台。
--- 参数
--- message :: LocalisedString
--- color :: Color (可选)
---@param color table?
---@param message table
function LuaPlayer:print(color, message) end

--- 将实体统计信息打印到玩家的控制台
--- 参数
--- entities :: array of string (可选): 要获取统计信息的实体原型。如果未指定或为空，
--- 则显示所有实体的统计信息。
---@param entities string[]? 要获取统计信息的实体原型。如果未指定或为空，则显示所有实体的统计信息。
function LuaPlayer:print_entity_statistics(entities) end

--- 打印每个 mod 的 LuaObject 数量。
function LuaPlayer:print_lua_object_statistics(...) end

--- 将建造机器人任务数量打印到玩家的控制台。
function LuaPlayer:print_robot_jobs(...) end

--- 移除所有匹配给定过滤条件的警报；如果给定空过滤表，则移除所有警报
--- 参数
--- 包含以下字段的表：
--- entity :: LuaEntity (可选)
--- prototype :: LuaEntityPrototype (可选)
--- position :: Position (可选)
--- type :: defines.alert_type (可选)
--- surface :: SurfaceSpecification (可选)
--- icon :: SignalID (可选)
--- message :: LocalisedString (可选)
---@param entity LuaEntity? entity :: LuaEntity（可选）
prototype :: LuaEntityPrototype（可选）
position :: Position（可选）
type :: defines.alert_type（可选）
surface :: SurfaceSpecification（可选）
icon :: SignalID（可选）
message :: LocalisedString（可选）
function LuaPlayer:remove_alert(entity) end

--- 从此实体中移除物品。
--- 参数
--- items :: ItemStackSpecification: 要移除的物品。
--- 返回值
--- 实际移除的物品数量。
---@return integer count
---@param items table 要移除的物品。
function LuaPlayer:remove_item(items) end

--- 设置给定屏幕页正在使用哪个快捷栏页面
--- 参数
--- screen_index :: uint: 屏幕页。索引 1 是界面中的顶行。索引可以超出屏幕上可见的栏数，以适应界面配置设置的变化。
--- page_index :: uint: 新的快捷栏页面。
---@param page_index integer 新的快捷栏页面。
---@param screen_index integer 屏幕页。索引 1 是界面中的顶行。索引可以超出屏幕上可见的快捷栏数量，以适配界面配置设置的更改。
function LuaPlayer:set_active_quick_bar_page(page_index, screen_index) end

--- 设置玩家的控制器类型。
--- 参数
--- 包含以下字段的表：
--- type :: defines.controllers: 使用哪个控制器
--- character :: LuaEntity (可选): 要控制的实体。当
--- type
--- 为 defines.controllers.character 时必填，否则忽略。
--- waypoints (可选): 过场动画控制器的路径点列表。当
--- type
--- 为 defines.controllers.cutscene 时此参数必填。每个路径点是一个表：
--- position :: Position (可选): 平移摄像机到的位置。
--- target :: LuaEntity 或 LuaUnitGroup (可选): 平移摄像机对准的实体或单位组。
--- transition_time :: uint: 从上一个路径点到达此路径点所需的 tick 数。
--- time_to_wait :: uint: 在移动到下一个路径点之前等待的 tick 数。
--- zoom :: double (可选): 到达路径点时要设置的缩放级别。如果未指定，则使用
--- 上一个路径点的缩放。
--- chart_mode_cutoff :: double (可选): 如果指定，当缩放级别低于此值时，游戏将切换到图表模式（地图缩小
--- 渲染）。
--- final_transition_time :: uint (可选): 当
--- type
--- 为 defines.controllers.cutscene 时必填。
--- 它是摄像机从最后一个路径点平移回起始
--- 位置所需的 tick 数。
--- 注意： 将玩家设置为 defines.controllers.editor 会自动将该玩家提升为管理员并启用作弊模式。
--- 注意： 将玩家设置为 defines.controllers.editor 还要求调用方玩家是管理员。
---@param type defines.controllers? type :: defines.controllers：要使用的控制器
character :: LuaEntity（可选）：要控制的实体。当 `type` 为 defines.controllers.character 时必填，否则忽略。
waypoints（可选）：过场动画（cutscene）控制器的航点列表。当 `type` 为 defines.controllers.cutscene 时此参数必填。每个航点是一个表：
position :: Position（可选）：摄像机要平移到的位置。
target :: LuaEntity 或 LuaUnitGroup（可选）：摄像机要平移到的实体或单位组。
transition_time :: uint：从前一个航点到达此航点所需的 tick 数。
time_to_wait :: uint：在移动到下一个航点之前等待的 tick 数。
zoom :: double（可选）：到达航点时设置的缩放级别。未指定时使用前一个航点的缩放级别。
chart_mode_cutoff :: double（可选）：如果指定，当缩放级别低于此值时，游戏将切换到图表模式（地图缩小）渲染。
final_transition_time :: uint（可选）：当 `type` 为 defines.controllers.cutscene 时必填。它是摄像机从最后一个航点平移回起始位置所需的 tick 数。
function LuaPlayer:set_controller(type) end

--- 设置游戏结束时要显示的界面。
--- 参数
--- message :: LocalisedString: 要显示的消息。
--- file :: string (可选): 要显示的图片的路径。
---@param file string? 要显示的图像的路径。
---@param message table 要显示的消息。
function LuaPlayer:set_ending_screen_data(file, message) end

--- 设置目标窗口（左上角）中的文本。
--- 参数
--- text :: LocalisedString (可选): 要显示的文本。\n 可用于分隔行。传入空
--- 字符串或完全省略此参数将使目标窗口消失。
--- only_update :: boolean (可选): 当为
--- true
--- 时，不播放"目标已更新"的音效。
---@param only_update boolean? 当为 `true` 时，不播放“目标已更新”的声音。
---@param text table? 要显示的文本。可以使用 \n 来分隔行。传入空字符串或完全省略此参数将使目标窗口消失。
function LuaPlayer:set_goal_description(only_update, text) end

--- 创建一个指向此实体的箭头。这用于教程。示例请参见战役任务中的
--- control.lua
--- 。
--- 参数
--- 包含以下字段的表：
--- type :: string: 指向哪里。此字段决定哪些其他字段是必需的
--- 可以是
--- "nowhere"
--- 、
--- "goal"
--- 、
--- "entity_info"
--- 、
--- "active_window"
--- 、
--- "entity"
--- 、
--- "position"
--- "crafting_queue"
--- 或
--- "item_stack"
--- 。
--- 其他
--- type
--- 专属参数
--- entity
--- entity :: LuaEntity
--- position
--- position :: Position
--- crafting_queue
--- crafting_queueindex :: uint
--- item_stack
--- inventory_index :: defines.inventory
--- item_stack_index :: uint
--- source :: string: 可以是
--- "player"
--- 或
--- "target"
--- 。
---@param type string 包含以下字段的表：
type :: [string]：指向的位置。此字段决定哪些其他字段是必需的。可以是 "nowhere"、"goal"、"entity_info"、"active_window"、"entity"、"position"、"crafting_queue" 或 "item_stack"。
附加的 type 专属参数：
entity
entity :: [LuaEntity]
position
position :: [Position]
crafting_queue
crafting_queue index :: [uint]
item_stack
inventory_index :: [defines.inventory]
item_stack_index :: [uint]
source :: [string]：可以是 "player" 或 "target"。
function LuaPlayer:set_gui_arrow(type) end

--- 设置给定槽位的快捷栏过滤器
--- 参数
--- index :: uint: 槽位索引。1 为第一页第一个槽位，2 为第一页第二个槽位，11 为第二页第一个槽位，依此类推。
--- filter :: string 或 LuaItemPrototype 或 LuaItemStack: 过滤器或
--- nil
--- 。
---@param filter string | LuaItemPrototype | LuaItemStack 过滤器或 `nil`。
---@param index integer 栏位索引。1 表示第一页的第一个栏位，2 表示第一页的第二个栏位，11 表示第二页的第一个栏位，依此类推。
function LuaPlayer:set_quick_bar_slot(filter, index) end

--- 使自定义快捷方式可用或不可用
--- 参数
--- prototype_name :: string: 自定义快捷方式的原型名称。
--- available :: boolean
---@param available boolean
---@param prototype_name string 自定义快捷方式的原型名称。
function LuaPlayer:set_shortcut_available(available, prototype_name) end

--- 切换或取消切换自定义快捷方式
--- 参数
--- prototype_name :: string: 自定义快捷方式的原型名称。
--- toggled :: boolean
---@param prototype_name string 自定义快捷方式的原型名称。
---@param toggled boolean
function LuaPlayer:set_shortcut_toggled(prototype_name, toggled) end

--- 将实体传送到给定位置，可能传送到另一个地表
--- 参数
--- position :: Position: 传送到的位置。
--- surface :: SurfaceSpecification (可选): 要传送到的地表。如果未给出，将传送
--- 到实体当前所在的地表。
--- 返回值
--- 当实体成功传送时为
--- true
--- 。
--- 注意： 某些实体可能无法传送。例如，铁路信号
--- 不允许传送，对任何此类实体使用此方法时始终返回
--- false
--- 。
--- 注意： 你也可以传入 1 或 2 个数字作为参数，它们将被用作相对传送坐标
--- 'teleport(0, 1)'
--- 将实体向正方向移动 1 格
--- 'teleport(4)'
--- 将实体向正 x 方向移动 4 格。
---@return boolean ok
---@param position table 要传送到的位置。
---@param surface table? 要传送到的地表。如果未指定，将传送到实体当前所在的地表。
function LuaPlayer:teleport(position, surface) end

--- 解锁给定玩家的成就
--- 仅当这是本地玩家、该成就尚未解锁且成就是"achievement"类型时才有效
--- 参数
--- name :: string: 要解锁的成就的名称
---@param name string 要解锁的成就的名称。
function LuaPlayer:unlock_achievement(name) end

--- 取消静音给定警报类别的警报
--- 参数
--- alert_type :: defines.alert_type
--- 返回值
--- 警报类型是否已取消静音（如果未被静音则返回 false）。
---@return boolean ok
---@param alert_type defines.alert_type
function LuaPlayer:unmute_alert(alert_type) end

--- 选中一个实体，就像将鼠标悬停在它上方一样。
--- 参数
--- position :: Position: 要选中的实体的位置
---@param position table 要选择的实体的位置。
function LuaPlayer:update_selected_entity(position) end

--- 如果光标中的当前物品是胶囊，则使用它；否则不做任何事
--- 参数
--- position :: Position: 物品将被使用的位置。
---@param position table 物品将被使用的位置。
function LuaPlayer:use_from_cursor(position) end

--- 排队请求在指定位置缩放到世界视图。如果玩家已经在缩放到世界，该请求将仅设置位置（和缩放）
--- 渲染模式更改请求会在渲染下一帧之前处理
--- 参数
--- position :: Position
--- scale :: double (可选)
---@param position table
---@param scale number?
function LuaPlayer:zoom_to_world(position, scale) end

--- 用于测量脚本性能的对象。
---@class LuaProfiler
---@field help string 此对象支持的所有方法和属性。
---@field valid boolean (只读) 此对象是否有效？
LuaProfiler = {}

--- 重置计时器，同时重新启动它。
function LuaProfiler:reset(...) end

--- 重新启动计时器，但不重置它。
function LuaProfiler:restart(...) end

--- 停止计时器。
function LuaProfiler:stop(...) end

--- 可编程扬声器的控制行为。
---@class LuaProgrammableSpeakerControlBehavior
---@field circuit_condition table
---@field circuit_parameters table
---@field entity LuaEntity (只读) 此控制行为所属的实体。
---@field help string 此对象支持的所有方法和属性。
---@field type defines.control_behavior.type (只读) 此控制行为的具体类型。
---@field valid boolean (只读) 此对象是否有效？
LuaProgrammableSpeakerControlBehavior = {}

--- 参数
--- wire :: defines.wire_type: 连接到此实体的网络的导线颜色。
--- circuit_connector :: defines.circuit_connector_id (可选): 要获取电路网络的连接器
--- 对于具有多个电路网络连接器的实体必须指定。
--- 返回值
--- 电路网络或 nil。
---@return LuaCircuitNetwork result
---@param circuit_connector defines.circuit_connector_id? 要获取其电路网络的连接器。
对于拥有多个电路网络连接器的实体，必须指定此项。
---@param wire defines.wire_type 连接到此实体的网络的导线颜色。
function LuaProgrammableSpeakerControlBehavior:get_circuit_network(circuit_connector, wire) end

--- 用于向调用方 RCON 接口发送消息的接口。
---@class LuaRCON
LuaRCON = {}

--- 如果存在调用方 RCON 接口，则向其打印文本
--- 参数
--- message :: LocalisedString
---@param message table
function LuaRCON:print(message) end

--- 铁路链式信号灯的控制行为。
---@class LuaRailChainSignalControlBehavior
---@field blue_signal table
---@field entity LuaEntity (只读) 此控制行为所属的实体。
---@field green_signal table
---@field help string 此对象支持的所有方法和属性。
---@field orange_signal table
---@field red_signal table
---@field type defines.control_behavior.type (只读) 此控制行为的具体类型。
---@field valid boolean (只读) 此对象是否有效？
LuaRailChainSignalControlBehavior = {}

--- 参数
--- wire :: defines.wire_type: 连接到此实体的网络的导线颜色。
--- circuit_connector :: defines.circuit_connector_id (可选): 要获取电路网络的连接器
--- 对于具有多个电路网络连接器的实体必须指定。
--- 返回值
--- 电路网络或 nil。
---@return LuaCircuitNetwork result
---@param circuit_connector defines.circuit_connector_id? 要获取其电路网络的连接器。
对于拥有多个电路网络连接器的实体，必须指定此项。
---@param wire defines.wire_type 连接到此实体的网络的导线颜色。
function LuaRailChainSignalControlBehavior:get_circuit_network(circuit_connector, wire) end

--- 一条铁路路径。
---@class LuaRailPath
---@field current integer (只读) 当前铁路索引
---@field help string 此对象支持的所有方法和属性。
---@field rails table<integer, LuaEntity> (只读) 此路径经过的铁路
---@field size integer (只读) 此路径中铁路的总数
---@field total_distance number (只读) 路径的总距离
---@field travelled_distance number (只读) 已行进的总距离
---@field valid boolean (只读) 此对象是否有效？
LuaRailPath = {}

--- 铁路信号灯（rail signal）的控制行为。
---@class LuaRailSignalControlBehavior
---@field circuit_condition table 通过电路网络控制信号时使用的电路条件。
---@field close_signal boolean 是否根据电路条件关闭铁路信号灯。
---@field entity LuaEntity (只读) 该控制行为所属的实体。
---@field green_signal table
---@field help string 此对象支持的所有方法和属性。
---@field orange_signal table
---@field read_signal boolean 是否读取铁路信号灯的状态。
---@field red_signal table
---@field type defines.control_behavior.type (只读) 此控制行为的具体类型。
---@field valid boolean (只读) 此对象是否有效？
LuaRailSignalControlBehavior = {}

--- 参数
--- wire :: defines.wire_type：与此实体相连的网络的电线颜色。
--- circuit_connector :: defines.circuit_connector_id（可选）：要获取电路网络的连接器。对于拥有多个电路网络连接器的实体，必须指定该参数。
--- 返回值
--- 电路网络或 nil。
---@return LuaCircuitNetwork result
---@param circuit_connector defines.circuit_connector_id? 要获取其电路网络的连接器。
对于拥有多个电路网络连接器的实体，必须指定此项。
---@param wire defines.wire_type 连接到此实体的网络的导线颜色。
function LuaRailSignalControlBehavior:get_circuit_network(circuit_connector, wire) end

--- 一个独立于核心游戏随机生成器的确定性随机生成器，可以随时设置种子（seed）并重新设置种子。
--- 该随机生成器可以被保存和加载，并会保持其状态。
--- 注意：这与调用 math.random() 完全不同，你应该确定自己确实需要使用它而不是调用 math.random()。
--- 如果你不确定是否需要使用它而不是调用 math.random()，那么你可能并不需要它。
---@class LuaRandomGenerator
---@field help string 此对象支持的所有方法和属性。
---@field valid boolean (只读) 此对象是否有效？
LuaRandomGenerator = {}

--- 生成一个随机数。
--- 如果不给定任何参数，则返回 [0, 1) 范围内的一个数字。
--- 如果给定一个参数，则返回 [0, N] 范围内向下取整的数字。
--- 如果给定两个参数，则返回 [N1, N2] 范围内向下取整的数字。
--- 参数
--- lower :: double（可选）：结果的下界（包含该值）。
--- upper :: double（可选）：结果的上界（包含该值）。
---@return number count
---@param lower number? 结果的包含下限
---@param upper number? 结果的包含上限
function LuaRandomGenerator:___(lower, upper) end

--- 使用给定的值重新为随机生成器设置种子。
--- 参数
--- seed :: uint
--- 注意： 相近的种子会产生相似的结果。0 到 341 之间的种子会产生相同的结果。
---@param seed integer
function LuaRandomGenerator:re_seed(seed) end

--- 一个合成配方。配方属于势力（force，参见 LuaForce），因为某些配方是通过研究解锁的，而研究是按势力分别进行的。
---@class LuaRecipe
---@field category string (只读) 配方的类别。
---@field enabled boolean 配方是否可以使用。
---@field energy number (只读) 执行此配方所需的能量。这会直接影响合成时间：在合成速度恰好等于 1 的组装机中合成时，配方的能量值恰好等于其合成时间（以秒为单位）。
---@field force LuaForce (只读) 拥有此配方的势力。
---@field group LuaGroup (只读) 此配方的组（group）。
---@field help string 此对象支持的所有方法和属性。
---@field hidden boolean (只读) 配方是否隐藏？隐藏的配方不会显示在合成菜单中。
---@field hidden_from_flow_stats boolean 配方是否从产量统计（flow stats）中隐藏。
---@field ingredients table[] (只读) 此配方的原料。 示例 "steel-chest"（钢箱）配方将返回： { {type="item", name="steel-plate", amount=8} } 示例 "advanced-oil-processing"（高级石油处理）配方将返回： { {type="fluid", name="crude-oil", amount=10}, {type="fluid", name="water", amount=5} }
---@field localised_description table (只读)
---@field localised_name table (只读) 配方的本地化名称。
---@field name string (只读) 配方的名称。这可能与产物物品的名称不同，因为可能有多条配方可以制造同一种物品。
---@field order string (只读) 排序字符串。用于对合成菜单进行排序。
---@field products table[] (只读) 此配方的产物。
---@field prototype LuaRecipePrototype (只读) 此配方的原型（prototype）。
---@field subgroup LuaGroup (只读) 此配方的子组（subgroup）。
---@field valid boolean (只读) 此对象是否有效？
LuaRecipe = {}

--- 从原型重新加载配方。
function LuaRecipe:reload(...) end

--- 一个合成配方原型（prototype）。
---@class LuaRecipePrototype
---@field allow_as_intermediate boolean (只读) 此配方是否允许作为中间品进行手工合成。
---@field allow_decomposition boolean (只读) 此配方是否允许被分解以进行"完全原材料"（total-raw）计算。
---@field allow_intermediates boolean (只读) 手工合成时此配方是否允许使用中间配方。
---@field always_show_made_in boolean (只读) 此配方是否始终在提示框（tooltip）中显示"制造于"（made-in）。
---@field always_show_products boolean (只读) 配方提示框中是否始终显示产物。
---@field category string (只读) 配方的类别。
---@field emissions_multiplier number (只读) 此配方的排放倍率。
---@field enabled boolean (只读) 此配方原型是否默认启用（在游戏开始时即已启用）。
---@field energy number (只读) 执行此配方所需的能量。这会直接影响合成时间：在合成速度恰好等于 1 的组装机中合成时，配方的能量值恰好等于其合成时间（以秒为单位）。
---@field group LuaGroup (只读) 此配方的组（group）。
---@field help string 此对象支持的所有方法和属性。
---@field hidden boolean (只读) 配方是否隐藏？隐藏的配方不会显示在合成菜单中。
---@field hidden_from_flow_stats boolean (只读) 配方是否从产量统计（flow stats）中隐藏。
---@field ingredients table[] (只读) 此配方的原料。
---@field localised_description table (只读)
---@field localised_name table (只读) 配方的本地化名称。
---@field main_product table (只读) 此配方的主要产物；如果未定义主要产物则为 nil。
---@field name string (只读) 配方的名称。这可能与产物物品的名称不同，因为可能有多条配方可以制造同一种物品。
---@field order string (只读) 排序字符串。用于对合成菜单进行排序。
---@field overload_multiplier integer (只读) 用于确定在组装机被认为"足够满"之前还会放入多少额外物品。
---@field products table[] (只读) 此配方的产物。
---@field request_paste_multiplier integer (只读) 当此配方从组装机复制到请求箱（requester chest）时使用的倍率。 对于配方中的每种物品，请求箱中会设置为 物品数量 × 此值。
---@field show_amount_in_title boolean (只读) 当配方产出超过 1 个产物时，是否在配方提示框标题中显示数量。
---@field subgroup LuaGroup (只读) 此配方的子组（subgroup）。
---@field valid boolean (只读) 此对象是否有效？
LuaRecipePrototype = {}

--- 脚本之间接口的注册表。接口（interface）就是一个将名称映射到函数的字典。脚本或模组可以向 LuaRemote 注册接口，之后任何脚本都可以调用已注册的函数，前提是它知道接口名称和所需的函数名称。LuaRemote 的实例可通过名为 remote 的全局对象访问。
---@class LuaRemote
---@field interfaces table<string, table<string, boolean>> (只读) 所有已注册接口的列表。对于每个接口名称，remote.interfaces[name] 是一个字典，将该接口已注册的函数映射到值 true。 示例 假设 "human interactor" 接口已按上述方式注册： game.player.print(tostring(remote.interfaces["human interactor"]["hello"])) -- 输出 true game.player.print(tostring(remote.interfaces["human interactor"]["nonexistent"])) -- 输出 nil
LuaRemote = {}

--- 添加一个远程接口。
--- 参数
--- name :: string：接口的名称。
--- functions :: dictionary string → function：新接口所包含的函数列表。
--- 注意： 如果给定的接口名称已经被注册，则会报错。
---@param functions table<string, fun(...)> 作为新界面成员的函数列表。
---@param name string 界面的名称。
function LuaRemote:add_interface(functions, name) end

--- 调用某个接口的一个函数。
--- 参数
--- interface :: string：要在其中查找 function 的接口。
--- function :: string：属于 interface 的函数名称。
--- ...：要传递给被调用函数的参数。
--- 返回值
--- 任意值，包括大多数 LuaObject。
---@return any result
---@param ____ table 要传递给被调用函数的参数。
---@param _function string 属于 `interface` 的函数名称。
---@param interface string 要在其中查找 `function` 的界面。
function LuaRemote:call(____, _function, interface) end

--- 移除具有给定名称的接口。
--- 参数
--- name :: string：接口的名称。
--- 返回值
--- 接口是否被移除。如果接口不存在则返回 False。
---@return boolean ok
---@param name string 界面的名称。
function LuaRemote:remove_interface(name) end

--- 允许在游戏世界中渲染几何形状、文本和精灵图（sprite）。每个渲染对象由一个在整个游戏生命周期内全局唯一的 id 标识。
---@class LuaRendering
LuaRendering = {}

--- 销毁所有渲染对象。
--- 参数
--- mod_name :: string（可选）：如果提供，则只销毁由该模组创建的渲染对象。
---@param mod_name string? 如果提供，则只销毁由该模组创建的渲染对象。
function LuaRendering:clear(mod_name) end

--- 销毁具有给定 id 的对象。
--- 参数
--- id :: uint64
---@param id integer
function LuaRendering:destroy(id) end

--- 创建一个动画。
--- 参数
--- 包含以下字段的表：
--- animation :: string：一个 "animation" 原型的名称。
--- orientation :: float（可选）：动画的方向。默认值为 0。
--- x_scale :: double（可选）：动画的水平缩放比例。默认值为 1。
--- y_scale :: double（可选）：动画的垂直缩放比例。默认值为 1。
--- tint :: Color（可选）
--- render_layer :: RenderLayer（可选）
--- animation_speed :: double（可选）：动画每个 tick 前进的帧数。默认值为 1。
--- animation_offset :: double（可选）：动画的偏移量（以帧为单位）。默认值为 0。
--- orientation_target :: Position 或 LuaEntity（可选）：如果给定，动画会旋转以朝向此目标。注意 orientation 仍然会应用到动画上。
--- orientation_target_offset :: Vector（可选）：仅当 orientation_target 是 LuaEntity 时使用。
--- oriented_offset :: Vector（可选）：如果给定了 orientation_target，则偏移动画的中心。此偏移量会随动画一起旋转。
--- target :: Position 或 LuaEntity：动画的中心。
--- target_offset :: Vector（可选）：仅当 target 是 LuaEntity 时使用。
--- surface :: SurfaceSpecification
--- time_to_live :: uint（可选）：以 tick 为单位。默认永久存在。
--- forces :: array of ForceSpecification（可选）：此对象渲染给哪些势力。
--- players :: array of PlayerSpecification（可选）：此对象渲染给哪些玩家。
--- visible :: boolean（可选）：是否渲染给任何人。默认值为 true。
--- only_in_alt_mode :: boolean（可选）：是否仅在 alt 模式下渲染。默认值为 false。
--- 返回值
--- 渲染对象的 id。
---@return integer count
---@param animation string? animation :: string：“animation”（动画）原型的名称。
orientation :: float（可选）：动画的方向。默认为 0。
x_scale :: double（可选）：动画的水平缩放。默认为 1。
y_scale :: double（可选）：动画的垂直缩放。默认为 1。
tint :: Color（可选）
render_layer :: RenderLayer（可选）
animation_speed :: double（可选）：动画每个 tick 前进的帧数。默认为 1。
animation_offset :: double（可选）：动画的帧偏移量。默认为 0。
orientation_target :: Position 或 LuaEntity（可选）：如果给定，动画会旋转以面向此目标。注意 `orientation` 仍然会应用到动画上。
orientation_target_offset :: Vector（可选）：仅在 `orientation_target` 是 LuaEntity 时使用。
oriented_offset :: Vector（可选）：如果给出了 `orientation_target`，则偏移动画的中心。此偏移会随动画一起旋转。
target :: Position 或 LuaEntity：动画的中心。
target_offset :: Vector（可选）：仅在 `target` 是 LuaEntity 时使用。
surface :: SurfaceSpecification
time_to_live :: uint（可选）：以 tick 为单位。默认为永久存在。
forces :: array of ForceSpecification（可选）：该对象渲染给哪些势力。
players :: array of PlayerSpecification（可选）：该对象渲染给哪些玩家。
visible :: boolean（可选）：是否渲染给任何人。默认为 true。
only_in_alt_mode :: boolean（可选）：是否仅在 alt 模式下渲染。默认为 false。
function LuaRendering:draw_animation(animation) end

--- 创建一个弧。
--- 参数
--- 包含以下字段的表：
--- color :: Color
--- max_radius :: double：弧外缘的半径，以格（tile）为单位。
--- min_radius :: double：弧内缘的半径，以格为单位。
--- start_angle :: float：弧的起始位置，以弧度为单位。
--- angle :: float：弧的角度，以弧度为单位。
--- target :: Position 或 LuaEntity
--- target_offset :: Vector（可选）：仅当 target 是 LuaEntity 时使用。
--- surface :: SurfaceSpecification
--- time_to_live :: uint（可选）：以 tick 为单位。默认永久存在。
--- forces :: array of ForceSpecification（可选）：此对象渲染给哪些势力。
--- players :: array of PlayerSpecification（可选）：此对象渲染给哪些玩家。
--- visible :: boolean（可选）：是否渲染给任何人。默认值为 true。
--- draw_on_ground :: boolean（可选）：是否绘制在精灵图和实体之下。
--- only_in_alt_mode :: boolean（可选）：是否仅在 alt 模式下渲染。默认值为 false。
--- 返回值
--- 渲染对象的 id。
---@return integer count
---@param color table? color :: Color
max_radius :: double：圆弧外边缘的半径，以格为单位。
min_radius :: double：圆弧内边缘的半径，以格为单位。
start_angle :: float：圆弧的起始位置，以弧度为单位。
angle :: float：圆弧的角度，以弧度为单位。
target :: Position 或 LuaEntity
target_offset :: Vector（可选）：仅在 `target` 是 LuaEntity 时使用。
surface :: SurfaceSpecification
time_to_live :: uint（可选）：以 tick 为单位。默认为永久存在。
forces :: array of ForceSpecification（可选）：该对象渲染给哪些势力。
players :: array of PlayerSpecification（可选）：该对象渲染给哪些玩家。
visible :: boolean（可选）：是否渲染给任何人。默认为 true。
draw_on_ground :: boolean（可选）：是否应绘制在精灵和实体之下。
only_in_alt_mode :: boolean（可选）：是否仅在 alt 模式下渲染。默认为 false。
function LuaRendering:draw_arc(color) end

--- 创建一个圆。
--- 参数
--- 包含以下字段的表：
--- color :: Color
--- radius :: double：以格为单位。
--- width :: float（可选）：轮廓的宽度，仅在 filled = false 时使用。值以像素为单位（每格 32 像素）。
--- filled :: boolean：圆是否应填充。
--- target :: Position 或 LuaEntity
--- target_offset :: Vector（可选）：仅当 target 是 LuaEntity 时使用。
--- surface :: SurfaceSpecification
--- time_to_live :: uint（可选）：以 tick 为单位。默认永久存在。
--- forces :: array of ForceSpecification（可选）：此对象渲染给哪些势力。
--- players :: array of PlayerSpecification（可选）：此对象渲染给哪些玩家。
--- visible :: boolean（可选）：是否渲染给任何人。默认值为 true。
--- draw_on_ground :: boolean（可选）：是否绘制在精灵图和实体之下。
--- only_in_alt_mode :: boolean（可选）：是否仅在 alt 模式下渲染。默认值为 false。
--- 返回值
--- 渲染对象的 id。
---@return integer count
---@param color table? color :: Color
radius :: double：以格为单位。
width :: float（可选）：轮廓线的宽度，仅在 filled = false 时使用。数值以像素为单位（每格 32 像素）。
filled :: boolean：圆是否应填充。
target :: Position 或 LuaEntity
target_offset :: Vector（可选）：仅在 `target` 是 LuaEntity 时使用。
surface :: SurfaceSpecification
time_to_live :: uint（可选）：以 tick 为单位。默认为永久存在。
forces :: array of ForceSpecification（可选）：该对象渲染给哪些势力。
players :: array of PlayerSpecification（可选）：该对象渲染给哪些玩家。
visible :: boolean（可选）：是否渲染给任何人。默认为 true。
draw_on_ground :: boolean（可选）：是否应绘制在精灵和实体之下。
only_in_alt_mode :: boolean（可选）：是否仅在 alt 模式下渲染。默认为 false。
function LuaRendering:draw_circle(color) end

--- 创建一个光源。
--- 参数
--- 包含以下字段的表：
--- sprite :: SpritePath
--- orientation :: float（可选）：光源的方向。默认值为 0。
--- scale :: float（可选）：默认值为 1。
--- intensity :: float（可选）：默认值为 1。
--- minimum_darkness :: float（可选）：此光源开始渲染所需的最小黑暗度。默认值为 0。
--- oriented :: boolean（可选）：此光源是否与目标实体具有相同的方向，默认值为 false。注意 orientation 仍然会应用到精灵图上。
--- color :: Color（可选）：默认为白色（无色调）。
--- target :: Position 或 LuaEntity：光源的中心。
--- target_offset :: Vector（可选）：仅当 target 是 LuaEntity 时使用。
--- surface :: SurfaceSpecification
--- time_to_live :: uint（可选）：以 tick 为单位。默认永久存在。
--- forces :: array of ForceSpecification（可选）：此对象渲染给哪些势力。
--- players :: array of PlayerSpecification（可选）：此对象渲染给哪些玩家。
--- visible :: boolean（可选）：是否渲染给任何人。默认值为 true。
--- only_in_alt_mode :: boolean（可选）：是否仅在 alt 模式下渲染。默认值为 false。
--- 返回值
--- 渲染对象的 id。
--- 注意： 基础游戏使用工具精灵图 light_medium 和 light_small 作为光源。
---@return integer count
---@param sprite table? sprite :: SpritePath
orientation :: float（可选）：灯光的方向。默认为 0。
scale :: float（可选）：默认为 1。
intensity :: float（可选）：默认为 1。
minimum_darkness :: float（可选）：渲染此灯光所需的最低黑暗程度。默认为 0。
oriented :: boolean（可选）：此灯光是否与目标实体具有相同的方向，默认为 false。注意 `orientation` 仍然会应用到精灵上。
color :: Color（可选）：默认为白色（无染色）。
target :: Position 或 LuaEntity：灯光的中心。
target_offset :: Vector（可选）：仅在 `target` 是 LuaEntity 时使用。
surface :: SurfaceSpecification
time_to_live :: uint（可选）：以 tick 为单位。默认为永久存在。
forces :: array of ForceSpecification（可选）：该对象渲染给哪些势力。
players :: array of PlayerSpecification（可选）：该对象渲染给哪些玩家。
visible :: boolean（可选）：是否渲染给任何人。默认为 true。
only_in_alt_mode :: boolean（可选）：是否仅在 alt 模式下渲染。默认为 false。
function LuaRendering:draw_light(sprite) end

--- 创建一条线。
--- 参数
--- 包含以下字段的表：
--- color :: Color
--- width :: float：以像素为单位（每格 32 像素）。
--- gap_length :: double（可选）：线条中间隔的长度，以格为单位。默认值为 0。
--- dash_length :: double（可选）：线条中虚线的长度。仅当 gap_length > 0 时使用。默认值为 0。
--- from :: Position 或 LuaEntity
--- from_offset :: Vector（可选）：仅当 from 是 LuaEntity 时使用。
--- to :: Position 或 LuaEntity
--- to_offset :: Vector（可选）：仅当 to 是 LuaEntity 时使用。
--- surface :: SurfaceSpecification
--- time_to_live :: uint（可选）：以 tick 为单位。默认永久存在。
--- forces :: array of ForceSpecification（可选）：此对象渲染给哪些势力。
--- players :: array of PlayerSpecification（可选）：此对象渲染给哪些玩家。
--- visible :: boolean（可选）：是否渲染给任何人。默认值为 true。
--- draw_on_ground :: boolean（可选）：是否绘制在精灵图和实体之下。
--- only_in_alt_mode :: boolean（可选）：是否仅在 alt 模式下渲染。默认值为 false。
--- 返回值
--- 渲染对象的 id。
---@return integer count
---@param color table? color :: Color
width :: float：以像素为单位（每格 32 像素）。
gap_length :: double（可选）：该线条的间隙长度，以格为单位。默认为 0。
dash_length :: double（可选）：该线条的虚线段长度。仅在 gap_length > 0 时使用。默认为 0。
from :: Position 或 LuaEntity
from_offset :: Vector（可选）：仅在 `from` 是 LuaEntity 时使用。
to :: Position 或 LuaEntity
to_offset :: Vector（可选）：仅在 `to` 是 LuaEntity 时使用。
surface :: SurfaceSpecification
time_to_live :: uint（可选）：以 tick 为单位。默认为永久存在。
forces :: array of ForceSpecification（可选）：该对象渲染给哪些势力。
players :: array of PlayerSpecification（可选）：该对象渲染给哪些玩家。
visible :: boolean（可选）：是否渲染给任何人。默认为 true。
draw_on_ground :: boolean（可选）：是否应绘制在精灵和实体之下。
only_in_alt_mode :: boolean（可选）：是否仅在 alt 模式下渲染。默认为 false。
function LuaRendering:draw_line(color) end

--- 创建一个多边形。
--- 参数
--- 包含以下字段的表：
--- color :: Color
--- vertices :: array of ScriptRenderTarget
--- target :: Position 或 LuaEntity
--- target_offset :: Vector（可选）：仅当 target 是 LuaEntity 时使用。
--- surface :: SurfaceSpecification
--- time_to_live :: uint（可选）：以 tick 为单位。默认永久存在。
--- forces :: array of ForceSpecification（可选）：此对象渲染给哪些势力。
--- players :: array of PlayerSpecification（可选）：此对象渲染给哪些玩家。
--- visible :: boolean（可选）：是否渲染给任何人。默认值为 true。
--- draw_on_ground :: boolean（可选）：是否绘制在精灵图和实体之下。
--- only_in_alt_mode :: boolean（可选）：是否仅在 alt 模式下渲染。默认值为 false。
--- 返回值
--- 渲染对象的 id。
---@return integer count
---@param color table? color :: Color
vertices :: array of ScriptRenderTarget
target :: Position 或 LuaEntity
target_offset :: Vector（可选）：仅在 `target` 是 LuaEntity 时使用。
surface :: SurfaceSpecification
time_to_live :: uint（可选）：以 tick 为单位。默认为永久存在。
forces :: array of ForceSpecification（可选）：该对象渲染给哪些势力。
players :: array of PlayerSpecification（可选）：该对象渲染给哪些玩家。
visible :: boolean（可选）：是否渲染给任何人。默认为 true。
draw_on_ground :: boolean（可选）：是否应绘制在精灵和实体之下。
only_in_alt_mode :: boolean（可选）：是否仅在 alt 模式下渲染。默认为 false。
function LuaRendering:draw_polygon(color) end

--- 创建一个矩形。
--- 参数
--- 包含以下字段的表：
--- color :: Color
--- width :: float（可选）：轮廓的宽度，仅在 filled = false 时使用。值以像素为单位（每格 32 像素）。
--- filled :: boolean：矩形是否应填充。
--- left_top :: Position 或 LuaEntity
--- left_top_offset :: Vector（可选）：仅当 left_top 是 LuaEntity 时使用。
--- right_bottom :: Position 或 LuaEntity
--- right_bottom_offset :: Vector（可选）：仅当 right_bottom 是 LuaEntity 时使用。
--- surface :: SurfaceSpecification
--- time_to_live :: uint（可选）：以 tick 为单位。默认永久存在。
--- forces :: array of ForceSpecification（可选）：此对象渲染给哪些势力。
--- players :: array of PlayerSpecification（可选）：此对象渲染给哪些玩家。
--- visible :: boolean（可选）：是否渲染给任何人。默认值为 true。
--- draw_on_ground :: boolean（可选）：是否绘制在精灵图和实体之下。
--- only_in_alt_mode :: boolean（可选）：是否仅在 alt 模式下渲染。默认值为 false。
--- 返回值
--- 渲染对象的 id。
---@return integer count
---@param color table? color :: Color
width :: float（可选）：轮廓线的宽度，仅在 filled = false 时使用。数值以像素为单位（每格 32 像素）。
filled :: boolean：矩形是否应填充。
left_top :: Position 或 LuaEntity
left_top_offset :: Vector（可选）：仅在 `left_top` 是 LuaEntity 时使用。
right_bottom :: Position 或 LuaEntity
right_bottom_offset :: Vector（可选）：仅在 `right_bottom` 是 LuaEntity 时使用。
surface :: SurfaceSpecification
time_to_live :: uint（可选）：以 tick 为单位。默认为永久存在。
forces :: array of ForceSpecification（可选）：该对象渲染给哪些势力。
players :: array of PlayerSpecification（可选）：该对象渲染给哪些玩家。
visible :: boolean（可选）：是否渲染给任何人。默认为 true。
draw_on_ground :: boolean（可选）：是否应绘制在精灵和实体之下。
only_in_alt_mode :: boolean（可选）：是否仅在 alt 模式下渲染。默认为 false。
function LuaRendering:draw_rectangle(color) end

--- 创建一个精灵图。
--- 参数
--- 包含以下字段的表：
--- sprite :: SpritePath
--- orientation :: float（可选）：精灵图的方向。默认值为 0。
--- x_scale :: double（可选）：精灵图的水平缩放比例。默认值为 1。
--- y_scale :: double（可选）：精灵图的垂直缩放比例。默认值为 1。
--- tint :: Color（可选）
--- render_layer :: RenderLayer（可选）
--- orientation_target :: Position 或 LuaEntity（可选）：如果给定，精灵图会旋转以朝向此目标。注意 orientation 仍然会应用到精灵图上。
--- orientation_target_offset :: Vector（可选）：仅当 orientation_target 是 LuaEntity 时使用。
--- oriented_offset :: Vector（可选）：如果给定了 orientation_target，则偏移精灵图的中心。此偏移量会随精灵图一起旋转。
--- target :: Position 或 LuaEntity：精灵图的中心。
--- target_offset :: Vector（可选）：仅当 target 是 LuaEntity 时使用。
--- surface :: SurfaceSpecification
--- time_to_live :: uint（可选）：以 tick 为单位。默认永久存在。
--- forces :: array of ForceSpecification（可选）：此对象渲染给哪些势力。
--- players :: array of PlayerSpecification（可选）：此对象渲染给哪些玩家。
--- visible :: boolean（可选）：是否渲染给任何人。默认值为 true。
--- only_in_alt_mode :: boolean（可选）：是否仅在 alt 模式下渲染。默认值为 false。
--- 返回值
--- 渲染对象的 id。
---@return integer count
---@param sprite table? sprite :: SpritePath
orientation :: float（可选）：精灵的方向。默认为 0。
x_scale :: double（可选）：精灵的水平缩放。默认为 1。
y_scale :: double（可选）：精灵的垂直缩放。默认为 1。
tint :: Color（可选）
render_layer :: RenderLayer（可选）
orientation_target :: Position 或 LuaEntity（可选）：如果给定，精灵会旋转以面向此目标。注意 `orientation` 仍然会应用到精灵上。
orientation_target_offset :: Vector（可选）：仅在 `orientation_target` 是 LuaEntity 时使用。
oriented_offset :: Vector（可选）：如果给出了 `orientation_target`，则偏移精灵的中心。此偏移会随精灵一起旋转。
target :: Position 或 LuaEntity：精灵的中心。
target_offset :: Vector（可选）：仅在 `target` 是 LuaEntity 时使用。
surface :: SurfaceSpecification
time_to_live :: uint（可选）：以 tick 为单位。默认为永久存在。
forces :: array of ForceSpecification（可选）：该对象渲染给哪些势力。
players :: array of PlayerSpecification（可选）：该对象渲染给哪些玩家。
visible :: boolean（可选）：是否渲染给任何人。默认为 true。
only_in_alt_mode :: boolean（可选）：是否仅在 alt 模式下渲染。默认为 false。
function LuaRendering:draw_sprite(sprite) end

--- 创建一个文本。
--- 参数
--- 包含以下字段的表：
--- text :: LocalisedString：要显示的文本。
--- surface :: SurfaceSpecification
--- target :: Position 或 LuaEntity
--- target_offset :: Vector（可选）：仅当 target 是 LuaEntity 时使用。
--- color :: Color
--- scale :: double（可选）
--- font :: string（可选）：要使用的字体名称。默认与飘字（flying-text）使用相同的字体。
--- time_to_live :: uint（可选）：以 tick 为单位。默认永久存在。
--- forces :: array of ForceSpecification（可选）：此对象渲染给哪些势力。
--- players :: array of PlayerSpecification（可选）：此对象渲染给哪些玩家。
--- visible :: boolean（可选）：是否渲染给任何人。默认值为 true。
--- draw_on_ground :: boolean（可选）：是否绘制在精灵图和实体之下。
--- orientation :: float（可选）：文本的方向。默认值为 0。
--- alignment :: string（可选）：默认为 "left"。其他选项为 "right" 和 "center"。
--- scale_with_zoom :: boolean（可选）：默认为 false。如果为 true，文本会随玩家缩放（zoom）而缩放，从而使它在屏幕上始终是相同大小，而其相对游戏世界的尺寸会发生变化。
--- only_in_alt_mode :: boolean（可选）：是否仅在 alt 模式下渲染。默认值为 false。
--- 返回值
--- 渲染对象的 id。
--- 注意： 并非所有字体都支持缩放。
---@return integer count
---@param text table? - text :: LocalisedString：要显示的文本。
- surface :: SurfaceSpecification
- target :: Position 或 LuaEntity
- target_offset :: Vector (optional)：仅当 `target` 为 LuaEntity 时使用。
- color :: Color
- scale :: double (optional)
- font :: string (optional)：使用的字体名称。默认为与 flying-text 相同的字体。
- time_to_live :: uint (optional)：以 tick 为单位。默认为永久存在。
- forces :: array of ForceSpecification (optional)：该对象渲染给哪些势力。
- players :: array of PlayerSpecification (optional)：该对象渲染给哪些玩家。
- visible :: boolean (optional)：是否渲染给任何人。默认为 true。
- draw_on_ground :: boolean (optional)：是否绘制在精灵（sprite）与实体之下。
- orientation :: float (optional)：文本的方向。默认为 0。
- alignment :: string (optional)：默认为 "left"。其他选项为 "right" 与 "center"。
- scale_with_zoom :: boolean (optional)：默认为 false。若为 true，文本随玩家的缩放级别缩放，使其在屏幕上始终为相同大小，而相对游戏世界的大小则会改变。
- only_in_alt_mode :: boolean (optional)：是否仅在 alt 模式下渲染。默认为 false。
function LuaRendering:draw_text(text) end

--- 获取具有此 id 的文本的对齐方式；如果该对象不是文本则返回 nil。
--- 参数
--- id :: uint64
--- _仅当这是 Text 时才能使用_
---@return string result
---@param id integer
function LuaRendering:get_alignment(id) end

--- 获取所有有效对象 id 的数组。
--- 参数
--- mod_name :: string（可选）：如果提供，则只获取由该模组创建的渲染对象。
---@return integer[] count
---@param mod_name string? 若提供，则仅获取由该 mod 创建的渲染对象。
function LuaRendering:get_all_ids(mod_name) end

--- 获取具有此 id 的弧的角度；如果该对象不是弧则返回 nil。
--- 参数
--- id :: uint64
--- 返回值
--- 以弧度为单位的角度
--- _仅当这是 Arc 时才能使用_
---@return number count
---@param id integer
function LuaRendering:get_angle(id) end

--- 获取具有此 id 的动画的原型（prototype）名称；如果该对象不是动画则返回 nil。
--- 参数
--- id :: uint64
--- _仅当这是 Animation 时才能使用_
---@return string result
---@param id integer
function LuaRendering:get_animation(id) end

--- 获取具有此 id 的动画的偏移量；如果该对象不是动画则返回 nil。
--- 参数
--- id :: uint64
--- 返回值
--- 动画偏移量（以帧为单位）。
--- _仅当这是 Animation 时才能使用_
---@return number count
---@param id integer
function LuaRendering:get_animation_offset(id) end

--- 获取具有此 id 的动画的速度；如果该对象不是动画则返回 nil。
--- 参数
--- id :: uint64
--- 返回值
--- 动画速度（以每 tick 帧数为单位）。
--- _仅当这是 Animation 时才能使用_
---@return number count
---@param id integer
function LuaRendering:get_animation_speed(id) end

--- 获取具有此 id 的对象的颜色或色调。
--- 参数
--- id :: uint64
--- 返回值
--- 如果该对象不支持颜色则返回 nil。
--- _仅当这是 Text、Line、Circle、Rectangle、Arc、Polygon、Sprite、Light 或 Animation 时才能使用_
---@return table result
---@param id integer
function LuaRendering:get_color(id) end

--- 获取具有此 id 的线条的虚线长度；如果该对象不是线条则返回 nil。
--- 参数
--- id :: uint64
--- _仅当这是 Line 时才能使用_
---@return number count
---@param id integer
function LuaRendering:get_dash_length(id) end

--- 获取此对象是否绘制在地面上、大多数实体和精灵图之下。
--- 参数
--- id :: uint64
--- _仅当这是 Text、Line、Circle、Rectangle、Arc 或 Polygon 时才能使用_
---@return boolean ok
---@param id integer
function LuaRendering:get_draw_on_ground(id) end

--- 获取具有此 id 的圆或矩形是否填充；如果该对象不是圆或矩形则返回 nil。
--- 参数
--- id :: uint64
--- _仅当这是 Circle 或 Rectangle 时才能使用_
---@return boolean ok
---@param id integer
function LuaRendering:get_filled(id) end

--- 获取具有此 id 的文本的字体；如果该对象不是文本则返回 nil。
--- 参数
--- id :: uint64
--- _仅当这是 Text 时才能使用_
---@return string result
---@param id integer
function LuaRendering:get_font(id) end

--- 获取具有此 id 的对象渲染给哪些势力；如果对所有势力可见则返回 nil。
--- 参数
--- id :: uint64
---@return LuaForce[] result
---@param id integer
function LuaRendering:get_forces(id) end

--- 获取具有此 id 的线条从何处开始绘制；如果该对象不是线条则返回 nil。
--- 参数
--- id :: uint64
--- _仅当这是 Line 时才能使用_
---@return table result
---@param id integer
function LuaRendering:get_from(id) end

--- 获取具有此 id 的线条中间隔的长度；如果该对象不是线条则返回 nil。
--- 参数
--- id :: uint64
--- _仅当这是 Line 时才能使用_
---@return number count
---@param id integer
function LuaRendering:get_gap_length(id) end

--- 获取具有此 id 的光源的光照强度；如果该对象不是光源则返回 nil。
--- 参数
--- id :: uint64
--- _仅当这是 Light 时才能使用_
---@return number count
---@param id integer
function LuaRendering:get_intensity(id) end

--- 获取具有此 id 的矩形的左上角绘制在哪里；如果该对象不是矩形则返回 nil。
--- 参数
--- id :: uint64
--- _仅当这是 Rectangle 时才能使用_
---@return table result
---@param id integer
function LuaRendering:get_left_top(id) end

--- 获取具有此 id 的弧的外缘半径；如果该对象不是弧则返回 nil。
--- 参数
--- id :: uint64
--- _仅当这是 Arc 时才能使用_
---@return number count
---@param id integer
function LuaRendering:get_max_radius(id) end

--- 获取具有此 id 的弧的内缘半径；如果该对象不是弧则返回 nil。
--- 参数
--- id :: uint64
--- _仅当这是 Arc 时才能使用_
---@return number count
---@param id integer
function LuaRendering:get_min_radius(id) end

--- 获取具有此 id 的光源开始渲染所需的最小黑暗度；如果该对象不是光源则返回 nil。
--- 参数
--- id :: uint64
--- _仅当这是 Light 时才能使用_
---@return number count
---@param id integer
function LuaRendering:get_minimum_darkness(id) end

--- 获取此对象是否仅在 alt 模式（alt-mode）下渲染。
--- 参数
--- id :: uint64
---@return boolean ok
---@param id integer
function LuaRendering:get_only_in_alt_mode(id) end

--- 获取具有此 id 的文本、精灵图、光源或动画的方向；如果该对象不是文本、精灵图、光源或动画则返回 nil。
--- 参数
--- id :: uint64
--- _仅当这是 Text、Sprite、Light 或 Animation 时才能使用_
---@return number count
---@param id integer
function LuaRendering:get_orientation(id) end

--- 精灵图或动画会旋转以朝向此目标。注意 orientation 仍然会应用到精灵图或动画上。
--- 获取具有此 id 的精灵图或动画的 orientation_target；如果没有目标，或该对象不是精灵图或动画，则返回 nil。
--- 参数
--- id :: uint64
--- _仅当这是 Sprite 或 Animation 时才能使用_
---@return table result
---@param id integer
function LuaRendering:get_orientation_target(id) end

--- 获取具有此 id 的光源渲染时是否与目标实体具有相同的方向；如果该对象不是光源则返回 nil。
--- 注意 orientation 仍然会应用到精灵图上。
--- 参数
--- id :: uint64
--- _仅当这是 Light 时才能使用_
---@return boolean ok
---@param id integer
function LuaRendering:get_oriented(id) end

--- 如果给定了 orientation_target，则偏移精灵图或动画的中心。此偏移量会随精灵图或动画一起旋转。
--- 获取具有此 id 的精灵图或动画的 oriented_offset；如果该对象不是精灵图或动画则返回 nil。
--- 参数
--- id :: uint64
--- _仅当这是 Sprite 或 Animation 时才能使用_
---@return table result
---@param id integer
function LuaRendering:get_oriented_offset(id) end

--- 获取具有此 id 的对象渲染给哪些玩家；如果对所有玩家可见则返回 nil。
--- 参数
--- id :: uint64
---@return LuaPlayer[] player
---@param id integer
function LuaRendering:get_players(id) end

--- 获取具有此 id 的圆的半径；如果该对象不是圆则返回 nil。
--- 参数
--- id :: uint64
--- _仅当这是 Circle 时才能使用_
---@return number count
---@param id integer
function LuaRendering:get_radius(id) end

--- 获取具有此 id 的精灵图或动画的渲染层（render layer）；如果该对象不是精灵图或动画则返回 nil。
--- 参数
--- id :: uint64
--- _仅当这是 Sprite 或 Animation 时才能使用_
---@return table result
---@param id integer
function LuaRendering:get_render_layer(id) end

--- 获取具有此 id 的矩形的右下角绘制在哪里；如果该对象不是矩形则返回 nil。
--- 参数
--- id :: uint64
--- _仅当这是 Rectangle 时才能使用_
---@return table result
---@param id integer
function LuaRendering:get_right_bottom(id) end

--- 获取具有此 id 的文本或光源的缩放；如果该对象不是文本或光源则返回 nil。
--- 参数
--- id :: uint64
--- _仅当这是 Text 或 Light 时才能使用_
---@return number count
---@param id integer
function LuaRendering:get_scale(id) end

--- 获取具有此 id 的文本是否随玩家缩放（zoom）而缩放；如果该对象不是文本则返回 nil。
--- 参数
--- id :: uint64
--- _仅当这是 Text 时才能使用_
---@return boolean ok
---@param id integer
function LuaRendering:get_scale_with_zoom(id) end

--- 获取具有此 id 的精灵图或光源所使用的精灵图；如果该对象不是精灵图或光源则返回 nil。
--- 参数
--- id :: uint64
--- _仅当这是 Sprite 或 Light 时才能使用_
---@return table result
---@param id integer
function LuaRendering:get_sprite(id) end

--- 获取具有此 id 的弧的起始位置；如果该对象不是弧则返回 nil。
--- 参数
--- id :: uint64
--- 返回值
--- 以弧度为单位的角度
--- _仅当这是 Arc 时才能使用_
---@return number count
---@param id integer
function LuaRendering:get_start_angle(id) end

--- 具有此 id 的对象所渲染到的地表。
--- 参数
--- id :: uint64
---@return LuaSurface surface
---@param id integer
function LuaRendering:get_surface(id) end

--- 获取具有此 id 的对象绘制在哪里；如果该对象不支持目标（target）则返回 nil。
--- 参数
--- id :: uint64
--- _仅当这是 Text、Circle、Arc、Sprite、Light 或 Animation 时才能使用_
---@return table result
---@param id integer
function LuaRendering:get_target(id) end

--- 获取具有此 id 的文本所显示的内容；如果该对象不是文本则返回 nil。
--- 参数
--- id :: uint64
--- _仅当这是 Text 时才能使用_
---@return table result
---@param id integer
function LuaRendering:get_text(id) end

--- 获取具有此 id 的对象的生存时间（time to live）。如果该对象不会过期，则为 0。
--- 参数
--- id :: uint64
---@return integer count
---@param id integer
function LuaRendering:get_time_to_live(id) end

--- 获取具有此 id 的线条绘制到哪里；如果该对象不是线条则返回 nil。
--- 参数
--- id :: uint64
--- _仅当这是 Line 时才能使用_
---@return table result
---@param id integer
function LuaRendering:get_to(id) end

--- 获取给定对象的类型。类型包括 "text"、"line"、"circle"、"rectangle"、"arc"、"polygon"、"sprite"、"light" 和 "animation"。
--- 参数
--- id :: uint64
---@return string result
---@param id integer
function LuaRendering:get_type(id) end

--- 获取具有此 id 的多边形的顶点；如果该对象不是多边形则返回 nil。
--- 参数
--- id :: uint64
--- _仅当这是 Polygon 时才能使用_
---@return table[] result
---@param id integer
function LuaRendering:get_vertices(id) end

--- 获取此对象是否对任何人渲染。
--- 参数
--- id :: uint64
---@return boolean ok
---@param id integer
function LuaRendering:get_visible(id) end

--- 获取具有此 id 的对象的宽度。值以像素为单位（每格 32 像素）。
--- 参数
--- id :: uint64
--- 返回值
--- 如果该对象不支持宽度则返回 nil。
--- _仅当这是 Line、Circle 或 Rectangle 时才能使用_
---@return number count
---@param id integer
function LuaRendering:get_width(id) end

--- 获取具有此 id 的精灵图或动画的水平缩放比例；如果该对象不是精灵图或动画则返回 nil。
--- 参数
--- id :: uint64
--- _仅当这是 Sprite 或 Animation 时才能使用_
---@return number count
---@param id integer
function LuaRendering:get_x_scale(id) end

--- 获取具有此 id 的精灵图或动画的垂直缩放比例；如果该对象不是精灵图或动画则返回 nil。
--- 参数
--- id :: uint64
--- _仅当这是 Sprite 或 Animation 时才能使用_
---@return number count
---@param id integer
function LuaRendering:get_y_scale(id) end

--- 是否存在具有此名称的字体。
--- 参数
--- font_name :: string
---@return boolean ok
---@param font_name string 字体名称。
function LuaRendering:is_font_valid(font_name) end

--- 是否存在具有此 id 的有效对象。
--- 参数
--- id :: uint64
---@return boolean ok
---@param id integer
function LuaRendering:is_valid(id) end

--- 设置具有此 id 的文本的对齐方式。如果该对象不是文本则不执行任何操作。
--- 参数
--- id :: uint64
--- alignment :: string："left"、"right" 或 "center"。
--- _仅当这是 Text 时才能使用_
---@param alignment string "left"、"right" 或 "center"。
---@param id integer
function LuaRendering:set_alignment(alignment, id) end

--- 设置具有此 id 的弧的角度。如果该对象不是弧则不执行任何操作。
--- 参数
--- id :: uint64
--- angle :: float：以弧度为单位的角度
--- _仅当这是 Arc 时才能使用_
---@param angle number 以弧度为单位的角度。
---@param id integer
function LuaRendering:set_angle(angle, id) end

--- 设置具有此 id 的动画的原型（prototype）名称。如果该对象不是动画则不执行任何操作。
--- 参数
--- id :: uint64
--- animation :: string
--- _仅当这是 Animation 时才能使用_
---@param animation string 动画。
---@param id integer
function LuaRendering:set_animation(animation, id) end

--- 设置具有此 id 的动画的偏移量。如果该对象不是动画则不执行任何操作。
--- 参数
--- id :: uint64
--- animation_offset :: double：动画偏移量（以帧为单位）。
--- _仅当这是 Animation 时才能使用_
---@param animation_offset number 以帧为单位的动画偏移量。
---@param id integer
function LuaRendering:set_animation_offset(animation_offset, id) end

--- 设置具有此 id 的动画的速度。如果该对象不是动画则不执行任何操作。
--- 参数
--- id :: uint64
--- animation_speed :: double：动画速度（以每 tick 帧数为单位）。
--- _仅当这是 Animation 时才能使用_
---@param animation_speed number 以每 tick 帧数表示的动画速度。
---@param id integer
function LuaRendering:set_animation_speed(animation_speed, id) end

--- 设置具有此 id 的对象的颜色或色调。如果该对象不支持颜色则不执行任何操作。
--- 参数
--- id :: uint64
--- color :: Color
--- _仅当这是 Text、Line、Circle、Rectangle、Arc、Polygon、Sprite、Light 或 Animation 时才能使用_
---@param color table 颜色。
---@param id integer
function LuaRendering:set_color(color, id) end

--- 设置具有此 id 的矩形的角。如果该对象不是矩形则不执行任何操作。
--- 参数
--- id :: uint64
--- left_top :: Position 或 LuaEntity
--- left_top_offset :: Vector
--- right_bottom :: Position 或 LuaEntity
--- right_bottom_offset :: Vector
--- _仅当这是 Rectangle 时才能使用_
---@param id integer
---@param left_top table | LuaEntity 左上角。
---@param left_top_offset table 左上角偏移量。
---@param right_bottom table | LuaEntity 右下角。
---@param right_bottom_offset table 右下角偏移量。
function LuaRendering:set_corners(id, left_top, left_top_offset, right_bottom, right_bottom_offset) end

--- 设置具有此 id 的线条的虚线长度。如果该对象不是线条则不执行任何操作。
--- 参数
--- id :: uint64
--- dash_length :: double
--- _仅当这是 Line 时才能使用_
---@param dash_length number 虚线长度。
---@param id integer
function LuaRendering:set_dash_length(dash_length, id) end

--- 设置具有此 id 的线条中虚线的长度和间隔的长度。如果该对象不是线条则不执行任何操作。
--- 参数
--- id :: uint64
--- dash_length :: double
--- gap_length :: double
--- _仅当这是 Line 时才能使用_
---@param dash_length number 虚线长度。
---@param gap_length number 间隙长度。
---@param id integer
function LuaRendering:set_dashes(dash_length, gap_length, id) end

--- 设置此对象是否绘制在地面上、大多数实体和精灵图之下。
--- 参数
--- id :: uint64
--- draw_on_ground :: boolean
--- _仅当这是 Text、Line、Circle、Rectangle、Arc 或 Polygon 时才能使用_
---@param draw_on_ground boolean 是否绘制在地面（精灵与实体之下）。
---@param id integer
function LuaRendering:set_draw_on_ground(draw_on_ground, id) end

--- 设置具有此 id 的圆或矩形是否填充。如果该对象不是圆或矩形则不执行任何操作。
--- 参数
--- id :: uint64
--- filled :: boolean
--- _仅当这是 Circle 或 Rectangle 时才能使用_
---@param filled boolean 是否填充。
---@param id integer
function LuaRendering:set_filled(filled, id) end

--- 设置具有此 id 的文本的字体。如果该对象不是文本则不执行任何操作。
--- 参数
--- id :: uint64
--- font :: string
--- _仅当这是 Text 时才能使用_
---@param font string 字体。
---@param id integer
function LuaRendering:set_font(font, id) end

--- 设置具有此 id 的对象渲染给哪些势力。
--- 参数
--- id :: uint64
--- forces :: array of ForceSpecification：提供一个空数组会将对象设置为对所有势力可见。
---@param forces table[] 提供空数组将使该对象对所有势力可见。
---@param id integer
function LuaRendering:set_forces(forces, id) end

--- 设置具有此 id 的线条从何处开始绘制。如果该对象不是线条则不执行任何操作。
--- 参数
--- id :: uint64
--- from :: Position 或 LuaEntity
--- from_offset :: Vector（可选）
--- _仅当这是 Line 时才能使用_
---@param from table | LuaEntity 起始位置。
---@param from_offset table? 起始偏移量。
---@param id integer
function LuaRendering:set_from(from, from_offset, id) end

--- 设置具有此 id 的线条中间隔的长度。如果该对象不是线条则不执行任何操作。
--- 参数
--- id :: uint64
--- gap_length :: double
--- _仅当这是 Line 时才能使用_
---@param gap_length number 间隙长度。
---@param id integer
function LuaRendering:set_gap_length(gap_length, id) end

--- 设置具有此 id 的光源的光照强度。如果该对象不是光源则不执行任何操作。
--- 参数
--- id :: uint64
--- intensity :: float
--- _仅当这是 Light 时才能使用_
---@param id integer
---@param intensity number 强度。
function LuaRendering:set_intensity(id, intensity) end

--- 设置具有此 id 的矩形的左上角绘制在哪里。如果该对象不是矩形则不执行任何操作。
--- 参数
--- id :: uint64
--- left_top :: Position 或 LuaEntity
--- left_top_offset :: Vector（可选）
--- _仅当这是 Rectangle 时才能使用_
---@param id integer
---@param left_top table | LuaEntity 左上角。
---@param left_top_offset table? 左上角偏移量。
function LuaRendering:set_left_top(id, left_top, left_top_offset) end

--- 设置具有此 id 的弧的外缘半径。如果该对象不是弧则不执行任何操作。
--- 参数
--- id :: uint64
--- max_radius :: double
--- _仅当这是 Arc 时才能使用_
---@param id integer
---@param max_radius number 最大半径。
function LuaRendering:set_max_radius(id, max_radius) end

--- 设置具有此 id 的弧的内缘半径。如果该对象不是弧则不执行任何操作。
--- 参数
--- id :: uint64
--- min_radius :: double
--- _仅当这是 Arc 时才能使用_
---@param id integer
---@param min_radius number 最小半径。
function LuaRendering:set_min_radius(id, min_radius) end

--- 设置具有此 id 的光源开始渲染所需的最小黑暗度。如果该对象不是光源则不执行任何操作。
--- 参数
--- id :: uint64
--- minimum_darkness :: float
--- _仅当这是 Light 时才能使用_
---@param id integer
---@param minimum_darkness number 最低黑暗度。
function LuaRendering:set_minimum_darkness(id, minimum_darkness) end

--- 设置此对象是否仅在 alt 模式下渲染。
--- 参数
--- id :: uint64
--- only_in_alt_mode :: boolean
---@param id integer
---@param only_in_alt_mode boolean 是否仅在 alt 模式下渲染。
function LuaRendering:set_only_in_alt_mode(id, only_in_alt_mode) end

--- 设置具有此 id 的文本、精灵图、光源或动画的方向。如果该对象不是文本、精灵图、光源或动画则不执行任何操作。
--- 参数
--- id :: uint64
--- orientation :: float
--- _仅当这是 Text、Sprite、Light 或 Animation 时才能使用_
---@param id integer
---@param orientation number 方向。
function LuaRendering:set_orientation(id, orientation) end

--- 精灵图或动画会旋转以朝向此目标。注意 orientation 仍然会应用到精灵图或动画上。
--- 设置具有此 id 的精灵图或动画的 orientation_target。如果该对象不是精灵图或动画则不执行任何操作。
--- 如果精灵图或动画不应有 orientation_target，则设置为 nil。
--- 参数
--- id :: uint64
--- orientation_target :: Position 或 LuaEntity
--- orientation_target_offset :: Vector（可选）
--- _仅当这是 Sprite 或 Animation 时才能使用_
---@param id integer
---@param orientation_target table | LuaEntity 方向目标。
---@param orientation_target_offset table? 方向目标偏移量。
function LuaRendering:set_orientation_target(id, orientation_target, orientation_target_offset) end

--- 设置具有此 id 的光源渲染时是否与目标实体具有相同的方向。如果该对象不是光源则不执行任何操作。
--- 注意 orientation 仍然会应用到精灵图上。
--- 参数
--- id :: uint64
--- oriented :: boolean
--- _仅当这是 Light 时才能使用_
---@param id integer
---@param oriented boolean 是否定向（随方向旋转）。
function LuaRendering:set_oriented(id, oriented) end

--- 如果给定了 orientation_target，则偏移精灵图或动画的中心。此偏移量会随精灵图或动画一起旋转。
--- 设置具有此 id 的精灵图或动画的 oriented_offset。如果该对象不是精灵图或动画则不执行任何操作。
--- 参数
--- id :: uint64
--- oriented_offset :: Vector
--- _仅当这是 Sprite 或 Animation 时才能使用_
---@param id integer
---@param oriented_offset table 定向偏移量。
function LuaRendering:set_oriented_offset(id, oriented_offset) end

--- 设置具有此 id 的对象渲染给哪些玩家。
--- 参数
--- id :: uint64
--- players :: array of PlayerSpecification：提供一个空数组会将对象设置为对所有玩家可见。
---@param id integer
---@param players table[] 提供空数组将使该对象对所有玩家可见。
function LuaRendering:set_players(id, players) end

--- 设置具有此 id 的圆的半径。如果该对象不是圆则不执行任何操作。
--- 参数
--- id :: uint64
--- radius :: double
--- _仅当这是 Circle 时才能使用_
---@param id integer
---@param radius number 半径。
function LuaRendering:set_radius(id, radius) end

--- 设置具有此 id 的精灵图或动画的渲染层（render layer）。如果该对象不是精灵图或动画则不执行任何操作。
--- 参数
--- id :: uint64
--- render_layer :: RenderLayer
--- _仅当这是 Sprite 或 Animation 时才能使用_
---@param id integer
---@param render_layer table 渲染层。
function LuaRendering:set_render_layer(id, render_layer) end

--- 设置具有此 id 的矩形的右下角绘制在哪里。如果该对象不是矩形则不执行任何操作。
--- 参数
--- id :: uint64
--- right_bottom :: Position 或 LuaEntity
--- right_bottom_offset :: Vector（可选）
--- _仅当这是 Rectangle 时才能使用_
---@param id integer
---@param right_bottom table | LuaEntity 右下角。
---@param right_bottom_offset table? 右下角偏移量。
function LuaRendering:set_right_bottom(id, right_bottom, right_bottom_offset) end

--- 设置具有此 id 的文本或光源的缩放。如果该对象不是文本或光源则不执行任何操作。
--- 参数
--- id :: uint64
--- scale :: double
--- _仅当这是 Text 或 Light 时才能使用_
---@param id integer
---@param scale number 缩放比例。
function LuaRendering:set_scale(id, scale) end

--- 设置具有此 id 的文本是否随玩家缩放（zoom）而缩放，从而使它在屏幕上始终是相同大小，而其相对游戏世界的尺寸会发生变化。
--- 如果该对象不是文本则不执行任何操作。
--- 参数
--- id :: uint64
--- scale_with_zoom :: boolean
--- _仅当这是 Text 时才能使用_
---@param id integer
---@param scale_with_zoom boolean 是否随缩放级别缩放。
function LuaRendering:set_scale_with_zoom(id, scale_with_zoom) end

--- 设置具有此 id 的精灵图或光源所使用的精灵图。如果该对象不是精灵图或光源则不执行任何操作。
--- 参数
--- id :: uint64
--- sprite :: SpritePath
--- _仅当这是 Sprite 或 Light 时才能使用_
---@param id integer
---@param sprite table 精灵（sprite）路径。
function LuaRendering:set_sprite(id, sprite) end

--- 设置具有此 id 的弧的起始位置。如果该对象不是弧则不执行任何操作。
--- 参数
--- id :: uint64
--- start_angle :: float：以弧度为单位的角度
--- _仅当这是 Arc 时才能使用_
---@param id integer
---@param start_angle number 以弧度为单位的角度。
function LuaRendering:set_start_angle(id, start_angle) end

--- 设置具有此 id 的对象绘制在哪里。如果该对象不支持目标（target）则不执行任何操作。
--- 参数
--- id :: uint64
--- target :: Position 或 LuaEntity
--- target_offset :: Vector（可选）
--- _仅当这是 Text、Circle、Arc、Sprite、Light 或 Animation 时才能使用_
---@param id integer
---@param target table | LuaEntity 目标。
---@param target_offset table? 目标偏移量。
function LuaRendering:set_target(id, target, target_offset) end

--- 设置具有此 id 的文本所显示的内容。如果该对象不是文本则不执行任何操作。
--- 参数
--- id :: uint64
--- text :: LocalisedString
--- _仅当这是 Text 时才能使用_
---@param id integer
---@param text table 文本。
function LuaRendering:set_text(id, text) end

--- 设置具有此 id 的对象的生存时间。如果对象不应过期，则设置为 0。
--- 参数
--- id :: uint64
--- time_to_live :: uint
---@param id integer
---@param time_to_live integer 存活时间。
function LuaRendering:set_time_to_live(id, time_to_live) end

--- 设置具有此 id 的线条绘制到哪里。如果该对象不是线条则不执行任何操作。
--- 参数
--- id :: uint64
--- to :: Position 或 LuaEntity
--- to_offset :: Vector（可选）
--- _仅当这是 Line 时才能使用_
---@param id integer
---@param to table | LuaEntity 结束位置。
---@param to_offset table? 结束偏移量。
function LuaRendering:set_to(id, to, to_offset) end

--- 设置具有此 id 的多边形的顶点。如果该对象不是多边形则不执行任何操作。
--- 参数
--- id :: uint64
--- vertices :: array of ScriptRenderTarget
--- _仅当这是 Polygon 时才能使用_
---@param id integer
---@param vertices table[]
function LuaRendering:set_vertices(id, vertices) end

--- 设置此对象是否对任何人渲染。
--- 参数
--- id :: uint64
--- visible :: boolean
---@param id integer
---@param visible boolean
function LuaRendering:set_visible(id, visible) end

--- 设置具有此 id 的对象的宽度。如果该对象不支持宽度则不执行任何操作。值以像素为单位（每格 32 像素）。
--- 参数
--- id :: uint64
--- width :: float
--- _仅当这是 Line、Circle 或 Rectangle 时才能使用_
---@param id integer
---@param width number
function LuaRendering:set_width(id, width) end

--- 设置具有此 id 的精灵图或动画的水平缩放比例。如果该对象不是精灵图或动画则不执行任何操作。
--- 参数
--- id :: uint64
--- x_scale :: double
--- _仅当这是 Sprite 或 Animation 时才能使用_
---@param id integer
---@param x_scale number
function LuaRendering:set_x_scale(id, x_scale) end

--- 设置具有此 id 的精灵图或动画的垂直缩放比例。如果该对象不是精灵图或动画则不执行任何操作。
--- 参数
--- id :: uint64
--- y_scale :: double
--- _仅当这是 Sprite 或 Animation 时才能使用_
---@param id integer
---@param y_scale number
function LuaRendering:set_y_scale(id, y_scale) end

--- 机器人港口（roboport）的控制行为。
---@class LuaRoboportControlBehavior
---@field available_construction_output_signal table
---@field available_logistic_output_signal table
---@field entity LuaEntity (只读) 该控制行为所属的实体。
---@field help string 此对象支持的所有方法和属性。
---@field mode_of_operations defines.control_behavior.roboport.circuit_mode_of_operation
---@field total_construction_output_signal table
---@field total_logistic_output_signal table
---@field type defines.control_behavior.type (只读) 此控制行为的具体类型。
---@field valid boolean (只读) 此对象是否有效？
LuaRoboportControlBehavior = {}

--- 参数
--- wire :: defines.wire_type：与此实体相连的网络的电线颜色。
--- circuit_connector :: defines.circuit_connector_id（可选）：要获取电路网络的连接器。对于拥有多个电路网络连接器的实体，必须指定该参数。
--- 返回值
--- 电路网络或 nil。
---@return LuaCircuitNetwork result
---@param circuit_connector defines.circuit_connector_id? 要获取其电路网络的连接器。
对于拥有多个电路网络连接器的实体，必须指定此项。
---@param wire defines.wire_type 连接到此实体的网络的导线颜色。
function LuaRoboportControlBehavior:get_circuit_network(circuit_connector, wire) end

--- 运行时设置可以通过控制台命令以及拥有这些设置的模组来更改。
---@class LuaSettings
---@field global table<string, table> (只读)
---@field player table<string, table> (只读)
---@field startup table<string, table> (只读)
LuaSettings = {}

--- 参数
--- player :: LuaPlayer
--- 注意： 如果在操作过程中给定的玩家变得无效，则返回值可能会失效。
---@param player LuaPlayer
function LuaSettings:get_player_settings(player) end

--- 储液罐（storage tank）的控制行为。
---@class LuaStorageTankControlBehavior
---@field entity LuaEntity (只读) 该控制行为所属的实体。
---@field help string 此对象支持的所有方法和属性。
---@field type defines.control_behavior.type (只读) 此控制行为的具体类型。
---@field valid boolean (只读) 此对象是否有效？
LuaStorageTankControlBehavior = {}

--- 参数
--- wire :: defines.wire_type：与此实体相连的网络的电线颜色。
--- circuit_connector :: defines.circuit_connector_id（可选）：要获取电路网络的连接器。对于拥有多个电路网络连接器的实体，必须指定该参数。
--- 返回值
--- 电路网络或 nil。
---@return LuaCircuitNetwork result
---@param circuit_connector defines.circuit_connector_id? 要获取其电路网络的连接器。
对于拥有多个电路网络连接器的实体，必须指定此项。
---@param wire defines.wire_type 连接到此实体的网络的导线颜色。
function LuaStorageTankControlBehavior:get_circuit_network(circuit_connector, wire) end

--- GUI 元素的样式。对于特定的 GUI 元素，此处列出的所有属性可能为 nil（如果不可用）。
---@class LuaStyle
---@field bottom_cell_padding integer 表格单元格内容底部与边框之间的间距。 _仅当这是 LuaTableStyle 时才能使用_
---@field bottom_margin integer
---@field bottom_padding integer
---@field cell_padding integer (只写) 表格单元格内容与边框之间的间距。（将上/右/下/左内边距设置为该值） _仅当这是 LuaTableStyle 时才能使用_
---@field clicked_font_color table _仅当这是 LuaButtonStyle 时才能使用_
---@field clicked_vertical_offset integer _仅当这是 LuaButtonStyle 时才能使用_
---@field color table _仅当这是 LuaProgressBarStyle 时才能使用_
---@field column_alignments table (只读) 表格各列的对齐方式。
---@field disabled_font_color table _仅当这是 LuaButtonStyle 时才能使用_
---@field extra_bottom_margin_when_activated integer _仅当这是 ScrollPaneStyle 时才能使用_
---@field extra_left_margin_when_activated integer _仅当这是 ScrollPaneStyle 时才能使用_
---@field extra_padding_when_activated integer _仅当这是 ScrollPaneStyle 时才能使用_
---@field extra_right_margin_when_activated integer _仅当这是 ScrollPaneStyle 时才能使用_
---@field extra_top_margin_when_activated integer _仅当这是 ScrollPaneStyle 时才能使用_
---@field font string
---@field font_color table
---@field gui LuaGui (只读) 此样式的 LuaGuiElement 所属的 GUI。
---@field height integer (只写) 将最小和最大高度都设置为给定值。
---@field help string 此对象支持的所有方法和属性。
---@field horizontal_align string 控件（widget）内部内容的水平对齐方式，可选值为 "left"、"center" 或 "right"。
---@field horizontal_spacing integer 各个单元格之间的水平间距。 _仅当这是 LuaTableStyle、LuaFlowStyle 或 LuaHorizontalFlow 时才能使用_
---@field horizontally_squashable boolean GUI 元素是否可以在水平方向被压缩（被某个父元素的最大宽度压缩）。 这主要用于滚动面板（scroll-pane）。默认值为 false。
---@field horizontally_stretchable boolean GUI 元素是否在水平方向上拉伸其尺寸以匹配其他元素。
---@field hovered_font_color table _仅当这是 LuaButtonStyle 时才能使用_
---@field left_cell_padding integer 表格单元格内容左侧与边框之间的间距。 _仅当这是 LuaTableStyle 时才能使用_
---@field left_margin integer
---@field left_padding integer
---@field maximal_height integer
---@field maximal_width integer
---@field minimal_height integer
---@field minimal_width integer
---@field name string (只读) 此样式的名称。
---@field natural_height integer
---@field natural_width integer
---@field pie_progress_color table _仅当这是 LuaButtonStyle 时才能使用_
---@field right_cell_padding integer 表格单元格内容右侧与边框之间的间距。 _仅当这是 LuaTableStyle 时才能使用_
---@field right_margin integer
---@field right_padding integer
---@field single_line boolean _仅当这是 LabelStyle 时才能使用_
---@field stretch_image_to_widget_size boolean _仅当这是 ImageStyle 时才能使用_
---@field top_cell_padding integer 表格单元格内容顶部与边框之间的间距。 _仅当这是 LuaTableStyle 时才能使用_
---@field top_margin integer
---@field top_padding integer
---@field use_header_filler boolean _仅当这是 LuaFrameStyle 时才能使用_
---@field valid boolean (只读) 此对象是否有效？
---@field vertical_align string 控件内部内容的垂直对齐方式，可选值为 "top"、"center" 或 "bottom"。
---@field vertical_spacing integer 各个单元格之间的垂直间距。 _仅当这是 LuaTableStyle、LuaFlowStyle 或 LuaVerticalFlow 时才能使用_
---@field vertically_squashable boolean GUI 元素是否可以在垂直方向被压缩（被某个父元素的最大高度压缩）。 这主要用于滚动面板（scroll-pane）。滚动面板的默认（父级）值为 true，其他情况为 false。
---@field vertically_stretchable boolean GUI 元素是否在垂直方向上拉伸其尺寸以匹配其他元素。
---@field want_ellipsis boolean _仅当这是 LabelStyle 时才能使用_
---@field width integer (只写) 将最小和最大宽度都设置为给定值。
LuaStyle = {}

--- 世界的一个「域」。地表只能通过 API 创建和删除。地表由其名称唯一标识。每个游戏至少包含名为 "nauvis" 的地表。
---@class LuaSurface
---@field always_day boolean 当设置为 true 时，太阳将永远照耀。
---@field darkness number (只读) 当前时间的黑暗程度。
---@field dawn number 黎明开始时的白天时间。
---@field daytime number 当前一天中的时间，范围为 [0, 1) 的数字。
---@field dusk number 黄昏开始时的白天时间。
---@field evening number 傍晚开始时的白天时间。
---@field freeze_daytime boolean 当前是否冻结了白天时间。
---@field help string 此对象支持的所有方法和属性。
---@field index integer (只读) 与此地表关联的唯一 ID。
---@field map_gen_settings table 地表的地图生成设置。 可以在更改生成设置后用于调整地表。 注意： 在运行时更改设置时，游戏不会追溯更改任何内容。 注意： LuaSurface::regenerate_entity、LuaSurface::regenerate_decorative 和 LuaSurface::delete_chunk
---@field min_brightness number 夜间的最低亮度。默认为 0.15
---@field morning number 早晨开始时的白天时间。
---@field name string 此地表的名称。名称在地表间是唯一的。 注意： 默认地表不能重命名。
---@field peaceful_mode boolean 此地表是否启用了和平模式？
---@field solar_power_multiplier number 此地表太阳能功率的倍率。不能小于 0。 注意： 太阳能设备仍受其最大功率输出限制。
---@field ticks_per_day integer 此地表一天（一昼夜）的 tick 数。
---@field valid boolean (只读) 此对象是否有效？
---@field wind_orientation number 当前风向。
---@field wind_orientation_change number 每 tick 的风向变化。
---@field wind_speed number 当前风速。
LuaSurface = {}

--- 派一个群体去建立新的基地。
--- 参数
--- position :: Position：新基地的位置。
--- unit_count :: uint：派去执行建基地任务的虫子数量。
--- force :: ForceSpecification (可选)：新基地所属的势力。默认为敌人。
--- 注意： 指定的势力必须由 AI 控制；即
--- force.ai_controllable
--- 必须为
--- true
--- 。
---@param force table? 新基地所属的势力。默认为敌方(enemy)。
---@param position table 新基地的位置。
---@param unit_count integer 派去执行建基地任务的虫子(biter)数量。
function LuaSurface:build_enemy_base(force, position, unit_count) end

--- 如果在给定位置存在一个实体，可以用给定的实体参数进行快速替换，则返回 true。
--- 参数
--- 包含以下字段的表：
--- name :: string：要检查的实体名称
--- position :: Position：实体将被放置的位置
--- direction :: defines.direction (可选)：实体将被放置的方向
--- force :: ForceSpecification (可选)：将要放置该实体的势力。
--- 如果未指定，则假定为敌方势力。
---@return boolean ok
---@param name string? name :: string: 要检查的实体名称  
position :: Position: 实体将被放置的位置  
direction :: defines.direction (可选): 实体将被放置的方向  
force :: ForceSpecification (可选): 放置该实体的势力。如果未指定，则假定为敌方势力。
function LuaSurface:can_fast_replace(name) end

--- 检查与地形或其他实体的碰撞。
--- 参数
--- 包含以下字段的表：
--- name :: string：要检查的实体名称
--- position :: Position：实体将被放置的位置
--- direction :: defines.direction (可选)：实体将被放置的方向
--- force :: ForceSpecification (可选)：将要放置该实体的势力。如果未指定，则假定为敌方势力。
--- build_check_type :: defines.build_check_type (可选)：应执行哪种检查类型。
--- forced :: boolean (可选)：如果 defines.build_check_type 为 "ghost_place" 且此值为 true，则可标记为拆除的事物将被忽略。
---@return boolean ok
---@param name string? name :: string: 要检查的实体名称  
position :: Position: 实体将被放置的位置  
direction :: defines.direction (可选): 实体将被放置的方向  
force :: ForceSpecification (可选): 放置该实体的势力。如果未指定，则假定为敌方势力。  
build_check_type :: defines.build_check_type (可选): 应执行哪种检查类型。  
forced :: boolean (可选): 如果 defines.build_check_type 为 "ghost_place" 且此项为 true，则忽略可标记为拆除(deconstruction)的对象。
function LuaSurface:can_place_entity(name) end

--- 取消拆除指令。
--- 参数
--- 包含以下字段的表：
--- area :: BoundingBox：要取消拆除指令的区域。
--- force :: ForceSpecification：要取消其拆除指令的势力。
--- player :: PlayerSpecification (可选)：如果存在，则将其设为 last_user 的玩家。
--- skip_fog_of_war :: boolean (可选)：是否跳过战争迷雾覆盖的区块。
--- item :: LuaItemStack (可选)：如果存在，要使用的拆除物品。
---@param area table? area :: BoundingBox: 要取消拆除(deconstruction)指令的区域。  
force :: ForceSpecification: 要取消其拆除指令的势力。  
player :: PlayerSpecification (可选): 如果有的话，将其设置为 last_user 的玩家。  
skip_fog_of_war :: boolean (可选): 是否跳过被战争迷雾覆盖的区块。  
item :: LuaItemStack (可选): 如果有的话，要使用的拆除物品。
function LuaSurface:cancel_deconstruct_area(area) end

--- 取消升级指令。
--- 参数
--- 包含以下字段的表：
--- area :: BoundingBox：要取消升级指令的区域。
--- force :: ForceSpecification：要取消其升级指令的势力。
--- player :: PlayerSpecification (可选)：如果存在，则将其设为 last_user 的玩家。
--- skip_fog_of_war :: boolean (可选)：是否跳过战争迷雾覆盖的区块。
--- item :: LuaItemStack (可选)：如果存在，要使用的升级物品。
---@param area table? area :: BoundingBox: 要取消升级(upgrade)指令的区域。  
force :: ForceSpecification: 要取消其升级指令的势力。  
player :: PlayerSpecification (可选): 如果有的话，将其设置为 last_user 的玩家。  
skip_fog_of_war :: boolean (可选): 是否跳过被战争迷雾覆盖的区块。  
item :: LuaItemStack (可选): 如果有的话，要使用的升级物品。
function LuaSurface:cancel_upgrade_area(area) end

--- 清除此地表，删除其上的所有实体和区块。
--- 注意： 这不会立即清除地表。它将在当前 tick 结束时被清除。
function LuaSurface:clear(...) end

--- 清除此地表上的所有污染。
function LuaSurface:clear_pollution(...) end

--- 克隆给定的区域。
--- 参数
--- 包含以下字段的表：
--- source_area :: BoundingBox
--- destination_area :: BoundingBox
--- destination_surface :: SurfaceSpecification (可选)
--- destination_force :: LuaForce 或 string (可选)
--- clone_tiles :: boolean (可选)：是否应克隆地块
--- clone_entities :: boolean (可选)：是否应克隆实体
--- clone_decoratives :: boolean (可选)：是否应克隆装饰物
--- clear_destination :: boolean (可选)：是否应清除目标实体
--- expand_map :: boolean (可选)：当 destination_area 超出当前边界时，是否应扩展目标地表。默认为 false。
--- 注意： 每个实体都会触发 defines.events.on_entity_cloned 事件，然后触发 defines.events.on_area_cloned 事件。
--- 注意： 实体按始终可以创建的顺序克隆，例如先铁轨后火车。
---@param source_area table? source_area :: BoundingBox  
destination_area :: BoundingBox  
destination_surface :: SurfaceSpecification (可选)  
destination_force :: LuaForce 或 string (可选)  
clone_tiles :: boolean (可选): 是否克隆地面(tile)  
clone_entities :: boolean (可选): 是否克隆实体  
clone_decoratives :: boolean (可选): 是否克隆装饰物(decorative)  
clear_destination :: boolean (可选): 是否清除目标位置的实体  
expand_map :: boolean (可选): 当 destination_area 超出当前边界时，是否扩展目标地表(surface)。默认为 false。
function LuaSurface:clone_area(source_area) end

--- 克隆给定的实体。
--- 参数
--- 包含以下字段的表：
--- entities :: array of LuaEntity
--- destination_offset :: Vector
--- destination_surface :: SurfaceSpecification (可选)
--- destination_force :: ForceSpecification (可选)
--- snap_to_grid :: boolean (可选)
--- 注意： 每个实体都会触发 defines.events.on_entity_cloned 事件。
--- 注意： 实体按始终可以创建的顺序克隆，例如先铁轨后火车。
---@param entities LuaEntity[]? entities :: LuaEntity 数组  
destination_offset :: Vector  
destination_surface :: SurfaceSpecification (可选)  
destination_force :: ForceSpecification (可选)  
snap_to_grid :: boolean (可选)
function LuaSurface:clone_entities(entities) end

--- 统计给定区域中指定类型或名称的实体数量。工作方式与 LuaSurface::find_entities_filtered 相同，只是仅返回数量。由于它不会构造所有包装对象，如果只对实体数量感兴趣，则效率更高。如果未给出区域和位置，则搜索整个地表。如果同时指定了区域和位置，则只统计与位置匹配的实体。如果给出了位置和半径，则只统计该位置半径内的实体。
--- 参数
--- 包含以下字段的表：
--- area :: BoundingBox (可选)
--- position :: Position (可选)
--- radius :: double (可选)：如果与 position 一起给出，将统计该位置半径内的所有实体。
--- name :: string 或 array of string (可选)
--- type :: string 或 array of string (可选)
--- ghost_name :: string 或 array of string (可选)
--- ghost_type :: string 或 array of string (可选)
--- direction :: defines.direction 或 array of defines.direction (可选)
--- collision_mask :: CollisionMaskLayer 或 array of CollisionMaskLayer (可选)
--- force :: ForceSpecification 或 array of ForceSpecification (可选)
--- limit :: uint (可选)
--- invert :: boolean (可选)：是否应反转过滤器。
---@return integer count
---@param area table? area :: BoundingBox (可选)  
position :: Position (可选)  
radius :: double (可选): 如果与 position 一起给出，将统计该位置半径内的所有实体。  
name :: string 或 string 数组 (可选)  
type :: string 或 string 数组 (可选)  
ghost_name :: string 或 string 数组 (可选)  
ghost_type :: string 或 string 数组 (可选)  
direction :: defines.direction 或 defines.direction 数组 (可选)  
collision_mask :: CollisionMaskLayer 或 CollisionMaskLayer 数组 (可选)  
force :: ForceSpecification 或 ForceSpecification 数组 (可选)  
limit :: uint (可选)  
invert :: boolean (可选): 是否反转过滤器。
function LuaSurface:count_entities_filtered(area) end

--- 统计给定区域中指定名称的地块数量。工作方式与 LuaSurface::find_tiles_filtered 相同，只是仅返回数量。由于它不会构造所有包装对象，如果只对地块数量感兴趣，则效率更高。如果未给出区域，则搜索整个地表。如果给出了位置和半径，则只统计该位置半径内的地块。
--- 参数
--- 包含以下字段的表：
--- area :: BoundingBox (可选)
--- position :: Position (可选)：如果未与 radius 一起给出则忽略。
--- radius :: double (可选)：如果与 position 一起给出，将返回该位置半径内的所有实体。
--- name :: string 或 array of string (可选)
--- limit :: uint (可选)
--- has_hidden_tile :: boolean (可选)
--- collision_mask :: CollisionMaskLayer 或 array of CollisionMaskLayer (可选)
---@return integer count
---@param area table? area :: BoundingBox (可选)  
position :: Position (可选): 如果未与 radius 一起给出则被忽略。  
radius :: double (可选): 如果与 position 一起给出，将返回该位置半径内的所有实体。  
name :: string 或 string 数组 (可选)  
limit :: uint (可选)  
has_hidden_tile :: boolean (可选)  
collision_mask :: CollisionMaskLayer 或 CollisionMaskLayer 数组 (可选)
function LuaSurface:count_tiles_filtered(area) end

--- 将给定的装饰物添加到地表。每个 Decorative
--- name :: string
--- position :: Position
--- amount :: uint8
--- 参数
--- 包含以下字段的表：
--- check_collision :: boolean (可选)：是否应针对实体/地块检查碰撞。
--- decoratives :: array of Decorative
--- 注意： 这将与已存在的相同类型装饰物合并，实际上会增大 "amount" 字段。
---@param check_collision boolean? check_collision :: boolean (可选): 是否对实体/地面(tile)进行碰撞检测。  
decoratives :: Decorative 数组
function LuaSurface:create_decoratives(check_collision) end

--- 在此地表上创建一个实体。
--- 参数
--- 包含以下字段的表：
--- name :: string：要创建的实体原型名称。
--- position :: Position：在哪里创建实体。
--- direction :: defines.direction (可选)：创建后实体期望的朝向。
--- force :: ForceSpecification (可选)：实体的势力，默认为敌人。
--- target :: LuaEntity (可选)：新实体要攻击的具有生命值的实体。
--- source :: LuaEntity (可选)：源实体。用于光束。
--- fast_replace :: boolean (可选)：如果为 true，建造将尝试模拟快速替换建造。
--- player :: PlayerSpecification (可选)：如果给出，则将该玩家设为 last_user。如果 fast_replace 为 true，则使用该玩家模拟快速替换。
--- spill :: boolean (可选)：如果为 false，且 fast_replace 为 true、player 为 nil，快速替换产生的物品将被删除而不是掉落到地面。
--- raise_built :: boolean (可选)：如果为 true，则在成功创建实体时触发 defines.events.script_raised_built 事件。
--- create_build_effect_smoke :: boolean (可选)：如果为 false，则不会在新实体周围显示建造效果烟雾。
--- 额外的实体特定参数
--- assembling-machine
--- recipe :: string (可选)
--- beam
--- target_position :: Position (可选)：绝对目标位置，可用于替代目标实体（如果同时定义了实体和位置，实体优先）。
--- source_position :: Position (可选)：绝对源位置，可用于替代源实体（如果同时定义了实体和位置，实体优先）。
--- max_length :: uint (可选)：如果设置，当源与目标之间的距离大于此值时，光束将被销毁。
--- duration :: uint (可选)：如果设置，光束将在经过这么多 tick 后被销毁。
--- source_offset :: Vector (可选)：渲染光束时，源位置将按此值偏移。
--- container
--- bar :: uint (可选)：应设置红色限位条的物品栏索引。
--- flying-text
--- text :: LocalisedString：要显示的字符串。
--- color :: Color (可选)：显示文本的颜色。
--- render_player_index :: uint (可选)
--- entity-ghost
--- inner_name :: string：虚影中包含的实体原型名称。
--- expires :: boolean (可选)：如果为
--- false
--- ，虚影实体将不会过期。默认为
--- false
--- 。
--- fire
--- initial_ground_flame_count :: uint：地面火焰应以多少个小火焰创建。
--- inserter
--- conditions: 包含以下字段的表：
--- circuit :: CircuitCondition (可选)
--- logistics :: CircuitCondition (可选)
--- filters :: array of Filter
--- item-entity
--- stack :: SimpleItemStack：要创建的物品堆。
--- item-request-proxy
--- target :: LuaEntity：物品要运送到的目标。
--- modules :: dictionary string → uint：要从物流网络运送到目标实体的物品堆。
--- logistic-container
--- request_filters :: array of Filter (可选)
--- particle
--- movement :: Vector
--- height :: float
--- vertical_speed :: float
--- frame_speed :: float
--- projectile
--- speed :: double
--- max_range :: double
--- resource
--- amount :: uint
--- enable_tree_removal :: boolean (可选)：是否根据原型的树木移除值，为此资源实体正常移除碰撞的树木。默认为 true。
--- enable_cliff_removal :: boolean (可选)：是否移除碰撞的悬崖。默认为 true。
--- underground-belt
--- type :: string (可选)：
--- "output"
--- 或
--- "input"
--- ；默认为
--- "input"
--- 。
--- programmable-speaker
--- parameters :: ProgrammableSpeakerParameters (可选)
--- alert_parameters :: ProgrammableSpeakerAlertParameters (可选)
--- character-corpse
--- inventory_size :: uint (可选)
--- player_index :: uint (可选)
--- highlight-box
--- bounding_box :: BoundingBox (可选)
--- box_type :: CursorBoxRenderType (可选)
--- render_player_index :: uint (可选)
--- blink_interval :: uint (可选)
--- time_to_live :: uint (可选)
--- simple-entity-with-owner & simple-entity-with-force
--- render_player_index :: uint (可选)
--- 返回值
--- 创建的实体，如果创建失败则为
--- nil
--- 。
--- 示例
--- asm聽=聽game.surfaces[1].create_entity{name聽=聽"assembling-machine-1",聽position聽=聽{15,聽3},聽force聽=聽game.forces.player,聽recipe聽=聽"iron-stick"}
--- 示例
--- 创建带电路条件和过滤器的过滤器机械臂。
--- game.surfaces[1].create_entity{
--- 聽聽name聽=聽"filter-inserter",聽position聽=聽{20,聽15},聽force聽=聽game.player.force,
--- 聽聽conditions聽=聽{red聽=聽{name聽=聽"wood",聽count聽=聽3,聽operator聽=聽"&gt;"},
--- 聽聽聽聽聽聽聽聽聽聽聽聽聽聽green聽=聽{name聽=聽"iron-ore",聽count聽=聽1,聽operator聽=
--- 聽聽logistics聽=聽{name聽=聽"wood",聽count聽=聽3,聽operator聽=聽"="}},
--- 聽聽filters聽=聽{{index聽=聽1,聽name聽=聽"iron-ore"}}
--- }
--- 示例
--- 创建一个已设置请求 128 个铁板的请求箱。
--- game.surfaces[1].create_entity{
--- 聽聽name聽=聽"logistic-chest-requester",聽position聽=聽{game.player.position.x+3,聽game.player.position.y},
--- 聽聽force聽=聽game.player.force,聽request_filters聽=聽{{index聽=聽1,聽name聽=聽"iron-plate",聽count聽=聽128}}
--- }
--- 示例
--- game.surfaces[1].create_entity{name聽=聽"big-biter",聽position聽=聽{15,聽3},聽force聽=聽game.forces.player}聽--聽Friendly聽biter
--- game.surfaces[1].create_entity{name聽=聽"medium-biter",聽position聽=聽{15,聽3},聽force聽=聽game.forces.enemy}聽--聽Enemy聽biter
--- 示例
--- 在玩家位置朝北创建一个基础机械臂。
--- game.surfaces[1].create_entity{name聽=聽"inserter",聽position聽=聽game.player.position,聽direction聽=聽defines.direction.north}
---@return LuaEntity entity
---@param name string? name :: string: 要创建的实体原型名称。  
position :: Position: 创建实体的位置。  
direction :: defines.direction (可选): 实体创建后期望的朝向。  
force :: ForceSpecification (可选): 实体的势力，默认为敌方(enemy)。  
target :: LuaEntity (可选): 新实体要瞄准的、具有生命值的实体。  
source :: LuaEntity (可选): 源实体。用于光束(beam)。  
fast_replace :: boolean (可选): 如果为 true，建造将尝试模拟快速替换建造。  
player :: PlayerSpecification (可选): 如果给出，则将 last_user 设置为此玩家。如果 fast_replace 为 true，则模拟该玩家执行快速替换。  
spill :: boolean (可选): 如果为 false、fast_replace 为 true 且 player 为 nil，则快速替换产生的物品将被删除，而不是掉落在地上。  
raise_built :: boolean (可选): 如果为 true，实体成功创建时将触发 defines.events.script_raised_built 事件。  
create_build_effect_smoke :: boolean (可选): 如果为 false，则不会在新实体周围显示建造效果的烟雾。  
额外的实体专属参数  
assembling-machine (组装机)  
recipe :: string (可选)  
beam (光束)  
target_position :: Position (可选): 绝对目标位置，可用于替代目标实体（如果实体和位置都定义了，实体优先）。  
source_position :: Position (可选): 绝对源位置，可用于替代源实体（如果实体和位置都定义了，实体优先）。  
max_length :: uint (可选): 如果设置，当源与目标之间的距离大于该值时，光束将被摧毁。  
duration :: uint (可选): 如果设置，光束将在经过该数值的 tick 后被摧毁。  
source_offset :: Vector (可选): 渲染光束时，源位置将偏移该值。  
container (容器)  
bar :: uint (可选): 应设置红色限制条所在的物品栏索引。  
flying-text (飘浮文本)  
text :: LocalisedString: 要显示的字符串。  
color :: Color (可选): 显示文本的颜色。  
render_player_index :: uint (可选)  
entity-ghost (实体虚影)  
inner_name :: string: 虚影(ghost)中包含的实体的原型名称。  
expires :: boolean (可选): 如果为 false，虚影实体将不会过期。默认为 false。  
fire (火焰)  
initial_ground_flame_count :: uint: 地面火焰应以多少个小火苗创建。  
inserter (机械臂)  
conditions: 包含以下字段的表:   
circuit :: CircuitCondition (可选)  
logistics :: CircuitCondition (可选)  
filters :: Filter 数组  
item-entity (物品实体)  
stack :: SimpleItemStack: 要创建的物品堆叠。  
item-request-proxy (物品请求代理)  
target :: LuaEntity: 目标物品将被送达的实体。  
modules :: dictionary string → uint: 要从物流(logistic)网络送达至目标实体的物品堆叠。  
logistic-container (物流容器)  
request_filters :: Filter 数组 (可选)  
particle (粒子)  
movement :: Vector  
height :: float  
vertical_speed :: float  
frame_speed :: float  
projectile (抛射物)  
speed :: double  
max_range :: double  
resource (资源)  
amount :: uint  
enable_tree_removal :: boolean (可选): 对于该资源实体，是否根据原型的树木移除值正常移除碰撞的树木。默认为 true。  
enable_cliff_removal :: boolean (可选): 是否移除碰撞的悬崖(cliff)。默认为 true。  
underground-belt (地下传送带)  
type :: string (可选): `"output"` 或 `"input"`；默认为 `"input"`。  
programmable-speaker (可编程扬声器)  
parameters :: ProgrammableSpeaker Parameters (可选)  
alert_parameters :: ProgrammableSpeakerAlert Parameters (可选)  
character-corpse (角色尸体)  
inventory_size :: uint (可选)  
player_index :: uint (可选)  
highlight-box (高亮框)  
bounding_box :: BoundingBox (可选)  
box_type :: CursorBoxRenderType (可选)  
render_player_index :: uint (可选)  
blink_interval :: uint (可选)  
time_to_live :: uint (可选)  
simple-entity-with-owner & simple-entity-with-force  
render_player_index :: uint (可选)
function LuaSurface:create_entity(name) end

--- 参数
--- 包含以下字段的表：
--- name :: string：要创建的烟雾原型名称。
--- position :: Position：在哪里创建烟雾。
---@param name string name :: string: 要创建的烟雾(smoke)原型名称。  
position :: Position: 创建烟雾的位置。
function LuaSurface:create_trivial_smoke(name) end

--- 在给定位置创建新的单位组。
--- 参数
--- 包含以下字段的表：
--- position :: Position：新单位组的初始位置。
--- force :: ForceSpecification (可选)：新单位组的势力。默认为
--- "enemy"
--- 。
---@return LuaUnitGroup unitGroup
---@param position table? position :: Position: 新单位群(unit group)的初始位置。  
force :: ForceSpecification (可选): 新单位群的势力。默认为 `"enemy"`。
function LuaSurface:create_unit_group(position) end

--- 放置拆除请求。
--- 参数
--- 包含以下字段的表：
--- area :: BoundingBox：要标记拆除的区域。
--- force :: ForceSpecification：其机器人应执行拆除的势力。
--- player :: PlayerSpecification (可选)：如果存在，则将其设为 last_user 的玩家。
--- skip_fog_of_war :: boolean (可选)：是否跳过战争迷雾覆盖的区块。
--- item :: LuaItemStack (可选)：如果存在，要使用的拆除物品。
---@param area table? area :: BoundingBox: 要标记为拆除(deconstruction)的区域。  
force :: ForceSpecification: 执行拆除的机器人(bot)所属的势力。  
player :: PlayerSpecification (可选): 如果有的话，将其设置为 last_user 的玩家。  
skip_fog_of_war :: boolean (可选): 是否跳过被战争迷雾覆盖的区块。  
item :: LuaItemStack (可选): 如果有的话，要使用的拆除物品。
function LuaSurface:deconstruct_area(area) end

--- 参数
--- prototype :: string：要检查的装饰物原型
--- position :: Position：要检查的位置
---@param position table 要检查的位置
---@param prototype string 要检查的装饰物(decorative)原型
function LuaSurface:decorative_prototype_collides(position, prototype) end

--- 参数
--- position :: ChunkPosition：要删除的区块位置
--- 注意： 这不会立即删除区块。区块将在当前 tick 结束时被删除。
---@param position table 要删除的区块位置
function LuaSurface:delete_chunk(position) end

--- 从给定区域移除所有装饰物。如果未给出区域和位置，则搜索整个地表。
--- 参数
--- 包含以下字段的表：
--- area :: BoundingBox (可选)
--- position :: TilePosition (可选)
--- name :: string 或 array of string 或 LuaDecorativePrototype 或 array of LuaDecorativePrototype (可选)
--- limit :: uint (可选)
--- invert :: boolean (可选)：是否应反转过滤器。
---@param area table? area :: BoundingBox (可选)  
position :: TilePosition (可选)  
name :: string、string 数组、LuaDecorativePrototype 或 LuaDecorativePrototype 数组 (可选)  
limit :: uint (可选)  
invert :: boolean (可选): 是否反转过滤器。
function LuaSurface:destroy_decoratives(area) end

--- 参数
--- prototype :: EntityPrototypeSpecification：要检查的实体原型
--- position :: Position：要检查的位置
--- use_map_generation_bounding_box :: boolean：是否应使用地图生成边界框而不是碰撞边界框
--- direction :: defines.direction (可选)
---@param direction defines.direction?
---@param position table 要检查的位置
---@param prototype table 要检查的实体原型
---@param use_map_generation_bounding_box boolean 是否使用地图生成的边界框(bounding box)而非碰撞边界框
function LuaSurface:entity_prototype_collides(direction, position, prototype, use_map_generation_bounding_box) end

--- 在给定区域中查找指定名称的装饰物。如果未给出过滤器，则返回搜索区域中的所有装饰物。如果指定了多个过滤器，则只返回与所有给定过滤器匹配的装饰物。如果未给出区域和位置，则搜索整个地表。每个 DecorativeResult 是一个表：
--- position :: TilePosition
--- decorative :: LuaDecorativePrototype
--- amount :: uint
--- 参数
--- 包含以下字段的表：
--- area :: BoundingBox (可选)
--- position :: TilePosition (可选)
--- name :: string 或 array of string 或 LuaDecorativePrototype 或 array of LuaDecorativePrototype (可选)
--- limit :: uint (可选)
--- invert :: boolean (可选)：是否应反转过滤器。
--- 示例
--- game.surfaces[1].find_decoratives_filtered{area聽=聽{{-10,聽-10},聽{10,聽10}},聽name聽=聽"sand-decal"}聽--聽gets聽all聽sand-decals聽in聽the聽rectangle
--- game.surfaces[1].find_decoratives_filtered{area聽=聽{{-10,聽-10},聽{10,聽10}},聽limit聽=聽5}聽聽--聽gets聽the聽first聽5聽decoratives聽in聽the聽rectangle
---@return table[] result
---@param area table? area :: BoundingBox (可选)  
position :: TilePosition (可选)  
name :: string、string 数组、LuaDecorativePrototype 或 LuaDecorativePrototype 数组 (可选)  
limit :: uint (可选)  
invert :: boolean (可选): 是否反转过滤器。
function LuaSurface:find_decoratives_filtered(area) end

--- 在区域内查找指定势力的敌方单位。
--- 参数
--- center :: Position：搜索区域的中心
--- radius :: double：圆形搜索区域的半径
--- force :: LuaForce 或 string (可选)：要查找其敌人的势力。如果未给出，则使用玩家势力。
--- 注意： 这比 LuaSurface::find_entities 更高效。
--- 示例
--- 查找所有有兴趣攻击玩家、且在 100 格范围内的单位。
--- local聽enemies聽=聽game.player.surface.find_enemy_units(game.player.position,聽100)
---@return LuaEntity[] entity
---@param center table 搜索区域的中心
---@param force LuaForce | string? 要查找其敌人的势力。如果未给出，则使用玩家势力。
---@param radius number 圆形搜索区域的半径
function LuaSurface:find_enemy_units(center, force, radius) end

--- 在给定区域中查找实体。如果未给出区域，则返回地表上的所有实体。
--- 参数
--- area :: BoundingBox (可选)
--- 示例
--- 将求值为给定区域内所有实体的列表。
--- game.surfaces["nauvis"].find_entities({{-10,聽-10},聽{10,聽10}})
---@return LuaEntity[] entity
---@param area table?
function LuaSurface:find_entities(area) end

--- 在给定区域中查找指定类型或名称的实体。如果未给出过滤器（
--- name
--- 、
--- type
--- 或
--- force
--- ），则返回搜索区域中的所有实体。如果指定了多个过滤器，则只返回与所有给定过滤器匹配的实体。如果未给出区域和位置，则搜索整个地表。如果同时指定了区域和位置，则只返回与位置匹配的实体。如果给出了位置和半径，则只返回该位置半径内的实体。
--- 参数
--- 包含以下字段的表：
--- area :: BoundingBox (可选)
--- position :: Position (可选)
--- radius :: double (可选)：如果与 position 一起给出，将返回该位置半径内的所有实体。
--- name :: string 或 array of string (可选)
--- type :: string 或 array of string (可选)
--- ghost_name :: string 或 array of string (可选)
--- ghost_type :: string 或 array of string (可选)
--- direction :: defines.direction 或 array of defines.direction (可选)
--- collision_mask :: CollisionMaskLayer 或 array of CollisionMaskLayer (可选)
--- force :: ForceSpecification 或 array of ForceSpecification (可选)
--- limit :: uint (可选)
--- invert :: boolean (可选)：是否应反转过滤器。
--- 示例
--- game.surfaces[1].find_entities_filtered{area聽=聽{{-10,聽-10},聽{10,聽10}},聽type聽=聽"resource"}聽--聽gets聽all聽resources聽in聽the聽rectangle
--- game.surfaces[1].find_entities_filtered{area聽=聽{{-10,聽-10},聽{10,聽10}},聽name聽=聽"iron-ore"}聽--聽gets聽all聽iron聽ores聽in聽the聽rectangle
--- game.surfaces[1].find_entities_filtered{area聽=聽{{-10,聽-10},聽{10,聽10}},聽name聽=聽{"iron-ore",聽"copper-ore"}}聽--聽gets聽all聽iron聽ore聽and聽copper聽ore聽in聽the聽rectangle
--- game.surfaces[1].find_entities_filtered{area聽=聽{{-10,聽-10},聽{10,聽10}},聽force聽=聽"player"}聽聽--聽gets聽player聽owned聽entities聽in聽the聽rectangle
--- game.surfaces[1].find_entities_filtered{area聽=聽{{-10,聽-10},聽{10,聽10}},聽limit聽=聽5}聽聽--聽gets聽the聽first聽5聽entities聽in聽the聽rectangle
--- game.surfaces[1].find_entities_filtered{position聽=聽{0,聽0},聽radius聽=聽10}聽聽--聽gets聽all聽entities聽within聽10聽tiles聽of聽the聽position聽[0,0].
---@return LuaEntity[] entity
---@param area table? area :: BoundingBox (可选)  
position :: Position (可选)  
radius :: double (可选): 如果与 position 一起给出，将返回该位置半径内的所有实体。  
name :: string 或 string 数组 (可选)  
type :: string 或 string 数组 (可选)  
ghost_name :: string 或 string 数组 (可选)  
ghost_type :: string 或 string 数组 (可选)  
direction :: defines.direction 或 defines.direction 数组 (可选)  
collision_mask :: CollisionMaskLayer 或 CollisionMaskLayer 数组 (可选)  
force :: ForceSpecification 或 ForceSpecification 数组 (可选)  
limit :: uint (可选)  
invert :: boolean (可选): 是否反转过滤器。
function LuaSurface:find_entities_filtered(area) end

--- 在特定位置查找特定实体。
--- 参数
--- entity :: string：要查找的实体
--- position :: Position：要查看的坐标
--- 返回值
--- 如果未找到此类实体，则为
--- nil
--- 。
--- 示例
--- game.player.selected.surface.find_entity('filter-inserter',聽{0,0})
---@return LuaEntity entity
---@param entity string 要查找的实体
---@param position table 要查看的坐标
function LuaSurface:find_entity(entity, position) end

--- 查找覆盖给定位置的物流网络。
--- 参数
--- position :: Position
--- force :: ForceSpecification：物流网络应属于的势力。
--- 返回值
--- 找到的网络，如果未找到此类网络则为
--- nil
--- 。
---@return LuaLogisticNetwork result
---@param force table 物流(logistic)网络所属的势力。
---@param position table
function LuaSurface:find_logistic_network_by_position(force, position) end

--- 查找所有其建造区域与给定位置相交的物流网络。
--- 参数
--- position :: Position
--- force :: ForceSpecification：物流网络应属于的势力。
---@return LuaLogisticNetwork[] result
---@param force table 这些物流(logistic)网络所属的势力。
---@param position table
function LuaSurface:find_logistic_networks_by_construction_area(force, position) end

--- 查找离给定位置最近的敌方单位。
--- 参数
--- 包含以下字段的表：
--- position :: Position：搜索区域的中心。
--- max_distance :: double：圆形搜索区域的半径。
--- force :: ForceSpecification (可选)：结果将作为其敌人的势力。如果未指定，则使用玩家势力。
--- 返回值
--- 最近的敌方单位，如果在给定区域内找不到敌人则为
--- nil
--- 。
---@return LuaEntity entity
---@param position table? position :: Position: 搜索区域的中心。  
max_distance :: double: 圆形搜索区域的半径。  
force :: ForceSpecification (可选): 结果将作为其敌人的势力。如果未指定，则使用玩家势力。
function LuaSurface:find_nearest_enemy(position) end

--- 在给定半径内查找一个无碰撞的位置。
--- 参数
--- name :: string：要为其查找位置的实体原型名称。（碰撞检查的边界框取自该原型。）
--- center :: Position：搜索区域的中心。
--- radius :: double：距
--- center
--- 的最大搜索距离。
--- 0
--- 表示无限大的搜索区域。
--- precision :: double：搜索时从给定位置开始的步长，以格为单位。最小值为 0.01。
--- force_to_tile_center :: boolean (可选)：只检查地块中心。当你的意图是在结果位置放置建筑时，这可能很有用，因为它们通常必须放置在地块中心。默认为 false。
--- 返回值
--- 无碰撞的位置。如果未找到合适的位置，则可能为
--- nil
--- 。
---@return table result
---@param center table 搜索区域的中心。
---@param force_to_tile_center boolean? 仅检查地块(tile)中心。当你打算将建筑放置在结果位置时这可能很有用，因为建筑通常必须放置在地块中心。默认为 false。
---@param name string 要为其寻找位置的实体的原型名称。(用于碰撞检测的边界框取自该原型。)
---@param precision number 搜索时从给定位置开始的步长，单位为地块(tile)。最小值为 0.01。
---@param radius number 距 `center` 的最大搜索距离。`0` 表示无限大的搜索区域。
function LuaSurface:find_non_colliding_position(center, force_to_tile_center, name, precision, radius) end

--- 在给定矩形内查找一个无碰撞的位置。
--- 参数
--- name :: string：要为其查找位置的实体原型名称。（碰撞检查的边界框取自该原型。）
--- search_space :: BoundingBox：要在其中搜索的矩形。
--- precision :: double：搜索时从给定位置开始的步长，以格为单位。最小值为 0.01。
--- force_to_tile_center :: boolean (可选)：只检查地块中心。当你的意图是在结果位置放置建筑时，这可能很有用，因为它们通常必须放置在地块中心。默认为 false。
--- 返回值
--- 无碰撞的位置。如果未找到合适的位置，则可能为
--- nil
--- 。
---@return table result
---@param force_to_tile_center boolean? 仅检查地块(tile)中心。当你打算将建筑放置在结果位置时这可能很有用，因为建筑通常必须放置在地块中心。默认为 false。
---@param name string 要为其寻找位置的实体的原型名称。(用于碰撞检测的边界框取自该原型。)
---@param precision number 搜索时从给定位置开始的步长，单位为地块(tile)。最小值为 0.01。
---@param search_space table 要在其中进行搜索的矩形区域。
function LuaSurface:find_non_colliding_position_in_box(force_to_tile_center, name, precision, search_space) end

--- 在给定区域中查找指定名称的地块。如果未给出过滤器，则返回搜索区域中的所有地块。如果未给出区域，则搜索整个地表。如果给出了位置和半径，则只包含该位置半径内的地块。
--- 参数
--- 包含以下字段的表：
--- area :: BoundingBox (可选)
--- position :: Position (可选)：如果未与 radius 一起给出则忽略。
--- radius :: double (可选)：如果与 position 一起给出，将返回该位置半径内的所有实体。
--- name :: string 或 array of string (可选)
--- limit :: uint (可选)
--- has_hidden_tile :: boolean (可选)
--- collision_mask :: CollisionMaskLayer 或 array of CollisionMaskLayer (可选)
---@return LuaTile[] tile
---@param area table? area :: BoundingBox (可选)  
position :: Position (可选): 如果未与 radius 一起给出则被忽略。  
radius :: double (可选): 如果与 position 一起给出，将返回该位置半径内的所有实体。  
name :: string 或 string 数组 (可选)  
limit :: uint (可选)  
has_hidden_tile :: boolean (可选)  
collision_mask :: CollisionMaskLayer 或 CollisionMaskLayer 数组 (可选)
function LuaSurface:find_tiles_filtered(area) end

--- 在给定区域内查找指定势力及势力条件的单位。
--- 参数
--- 包含以下字段的表：
--- area :: BoundingBox：要在其中查找单位的框。
--- force :: LuaForce 或 string：执行搜索的势力。
--- condition :: ForceCondition：只有满足条件的势力才会被包含在搜索中。
--- 注意： 这比 LuaSurface::find_entities 更高效。
--- 示例
--- 查找 "player" 的友方单位。
--- local聽friendly_units聽=聽game.player.surface.find_units({area聽=聽{{-10,聽-10},{10,聽10}},聽force聽=聽"player",聽condition聽=聽"friend")
--- 示例
--- 查找 "player" 的单位。
--- local聽units聽=聽game.player.surface.find_units({area聽=聽{{-10,聽-10},{10,聽10}},聽force聽=聽"player",聽condition聽=聽"same")
---@return LuaEntity[] entity
---@param area table area :: BoundingBox: 在其中查找单位的区域。  
force :: LuaForce 或 string: 执行搜索的势力。  
condition :: ForceCondition: 只有满足该条件的势力才会被纳入搜索。
function LuaSurface:find_units(area) end

--- 阻塞并生成所有已使用所有可用线程请求的区块。
function LuaSurface:force_generate_chunk_requests(...) end

--- 获取一个迭代器，遍历此地表上的每个区块。
---@return LuaChunkIterator result
function LuaSurface:get_chunks(...) end

--- 获取列表中离此位置最近的实体。
--- 参数
--- position :: Position
--- entities :: array of LuaEntity：要检查的实体
---@return LuaEntity entity
---@param entities LuaEntity[] 要检查的实体
---@param position table
function LuaSurface:get_closest(entities, position) end

--- 获取与给定地块位置水平或垂直相连的、所有指定类型的地块，包括给定的地块位置。
--- 参数
--- position :: Position：开始的地块位置。
--- tiles :: array of string：要搜索的地块。
--- 返回值
--- 得到的地块集合。
--- 注意： 这不会在未生成的区块中找到地块。
---@return table[] result
---@param position table 起始的地块位置。
---@param tiles string[] 要搜索的地块。
function LuaSurface:get_connected_tiles(position, tiles) end

--- 隐藏地块名称，如果给定位置没有则为
--- nil
--- 。
--- 参数
--- position :: TilePosition：地块位置。
---@return string result
---@param position table 地块位置。
function LuaSurface:get_hidden_tile(position) end

--- 获取此地表当前地图生成设置的地图交换字符串。
---@return string result
function LuaSurface:get_map_exchange_string(...) end

--- 获取给定位置的污染。
--- 参数
--- position :: Position
--- 注意： 污染按区块存储，因此同一区块内所有位置都将返回相同的值。
--- 示例
--- game.surfaces[1].get_pollution({1,2})
---@return number count
---@param position table
function LuaSurface:get_pollution(position) end

--- 获取一个随机的已生成区块位置；如果此地表上尚未生成任何区块，则返回 0,0。
---@return table result
function LuaSurface:get_random_chunk(...) end

--- 获取此地表上所有资源的资源量。
---@return table<string, integer> count
function LuaSurface:get_resource_counts(...) end

--- 获取与给定名称匹配的脚本区域；如果未给出名称，则返回所有区域。
--- 参数
--- name :: string (可选)
---@return table[] result
---@param name string?
function LuaSurface:get_script_areas(name) end

--- 获取与给定名称匹配的脚本位置；如果未给出名称，则返回所有位置。
--- 参数
--- name :: string (可选)
---@return table[] result
---@param name string?
function LuaSurface:get_script_positions(name) end

--- 获取此地表的起始区域半径。
---@return number count
function LuaSurface:get_starting_area_radius(...) end

--- 获取给定位置的地块。
--- 参数
--- x :: int
--- y :: int
--- 注意： 输入位置参数也可以是单个地块位置。
---@return LuaTile tile
---@param x integer
---@param y integer
function LuaSurface:get_tile(x, y) end

--- 通过遍历所有包含污染的区块，获取地表上的污染总量。
---@return number count
function LuaSurface:get_total_pollution(...) end

--- 获取匹配给定过滤器的火车站。
--- 参数
--- opts (可选)：包含以下字段的表：
--- name :: string 或 array of string (可选)
--- force :: ForceSpecification (可选)
---@return LuaEntity[] entity
---@param opts string | string[]? 包含以下字段的表:   
name :: string 或 string 数组 (可选)  
force :: ForceSpecification (可选)
function LuaSurface:get_train_stops(opts) end

--- 参数
--- force :: ForceSpecification (可选)：如果给出，只返回与此势力匹配的火车。
---@return LuaTrain[] train
---@param force table? 如果给定，则只返回属于该势力的列车。
function LuaSurface:get_trains(force) end

--- 给定的区块是否已生成？
--- 参数
--- position :: ChunkPosition：区块的位置。
---@return boolean ok
---@param position table 区块的位置。
function LuaSurface:is_chunk_generated(position) end

--- 在此地表播放声音。
--- 参数
--- 包含以下字段的表：
--- path :: SoundPath：要播放的声音
--- position :: Position (可选)：声音应在哪里播放。如果未给出，则在「任何地方」播放。
--- volume_modifier :: double (可选)：必须在 0 到 1（含）之间。
---@return boolean ok
---@param path table? path :: SoundPath：要播放的声音
position :: Position（可选）：声音播放的位置。若未给出，则在"所有地方"播放。
volume_modifier :: double（可选）：必须介于 0 到 1 之间（含两端）。
function LuaSurface:play_sound(path) end

--- 在给定位置生成污染。
--- 参数
--- source :: Position：在哪里生成污染。
--- amount :: double：要添加多少污染。
---@param amount number 要添加的污染量。
---@param source table 生成污染的位置。
function LuaSurface:pollute(amount, source) end

--- 向此地表上所有玩家的聊天控制台打印文本。
--- 参数
--- message :: LocalisedString
--- color :: Color (可选)
---@param color table?
---@param message table
function LuaSurface:print(color, message) end

--- 重新生成此地表上某些装饰物的自动放置。这可用于自动放置新添加的装饰物。
--- 参数
--- decoratives :: string 或 array of string (可选)
--- 要自动放置的装饰物原型名称。当为
--- nil
--- 时，使用所有具有自动放置的装饰物。
--- chunks :: array of ChunkPosition (可选)
--- 要在其上重新生成实体的区块位置。如果未给出，则重新生成所有区块。注意：状态 < entities 的区块会被忽略。
--- 注意： 所有指定的装饰物原型必须可自动放置。如果未给出任何内容，则在所有区块上生成所有装饰物。
---@param chunks table[]? 状态(status)小于 entities 的区块会被忽略。
---@param decoratives string | string[]?
function LuaSurface:regenerate_decorative(chunks, decoratives) end

--- 重新生成此地表上某些实体的自动放置。这可用于自动放置新添加的实体。
--- 参数
--- entities :: string 或 array of string (可选)
--- 要自动放置的实体原型名称。当为
--- nil
--- 时，使用所有具有自动放置的实体。
--- chunks :: array of ChunkPosition (可选)
--- 要在其上重新生成实体的区块位置。如果未给出，则重新生成所有区块。注意：状态 < entities 的区块会被忽略。
--- 注意： 所有指定的实体原型必须可自动放置。如果未给出任何内容，则在所有区块上生成所有实体。
---@param chunks table[]? 状态(status)小于 entities 的区块会被忽略。
---@param entities string | string[]?
function LuaSurface:regenerate_entity(chunks, entities) end

--- 启动寻路请求，而不实际命令单位移动。结果最终通过 defines.events.on_script_path_request_finished 事件异步返回。
--- 参数
--- 包含以下字段的表：
--- bounding_box :: BoundingBox
--- collision_mask :: CollisionMask 或 array of string
--- start :: Position
--- goal :: Position
--- force :: LuaForce 或 string
--- radius :: double (可选)：我们需要离目标多近。默认为 1。
--- pathfind_flags :: PathFindFlags (可选)：影响寻路器的标志。
--- can_open_gates :: boolean (可选)：寻路请求是否可以打开门。默认为 false。
--- path_resolution_modifier :: int (可选)：寻路的分辨率修正值。默认为 0。
--- 返回值
--- 一个唯一句柄，用于在 defines.events.on_script_path_request_finished 事件触发时标识此调用。
---@return integer count
---@param bounding_box table? bounding_box :: BoundingBox  
collision_mask :: CollisionMask 或 string 数组  
start :: Position  
goal :: Position  
force :: LuaForce 或 string  
radius :: double (可选): 需要到达目标的近距离。默认 1。  
pathfind_flags :: PathFindFlags (可选): 影响寻路器(pathfinder)的标志。  
can_open_gates :: boolean (可选): 寻路请求是否可以打开大门(gate)。默认 false。  
path_resolution_modifier :: int (可选): 寻路的解析度修正值。默认为 0。
function LuaSurface:request_path(bounding_box) end

--- 请求游戏的地图生成器在此地表上给定位置的指定半径内生成区块。
--- 参数
--- position :: Position：在哪里生成新区块。
--- radius :: uint：从
--- position
--- 开始生成新区块的区块半径。
---@param position table 生成新区块的位置。
---@param radius integer 以 `position` 为中心、要生成新区块的区块半径。
function LuaSurface:request_to_generate_chunks(position, radius) end

--- 设置区块的生成状态。在复制区块时很有用。
--- 参数
--- position :: ChunkPosition：区块的位置。
--- status :: defines.chunk_generated_status：区块的新状态。
---@param position table 区块的位置。
---@param status defines.chunk_generated_status 区块的新状态。
function LuaSurface:set_chunk_generated_status(position, status) end

--- 参数
--- position :: TilePosition：地块位置。
--- tile :: string 或 LuaTilePrototype：新的隐藏地块，或
--- nil
--- 以清除隐藏地块。
---@param position table 地块位置。
---@param tile string | LuaTilePrototype 新的隐藏地块；若为 `nil` 则清除隐藏地块。
function LuaSurface:set_hidden_tile(position, tile) end

--- 向多个单位下达命令。这将自动为任务选择合适的单位。
--- 参数
--- 包含以下字段的表：
--- command :: Command
--- unit_count :: uint：要下达命令的单位数量。
--- force :: ForceSpecification (可选)：此命令要下达给的单位的势力。如果未指定，则使用敌方势力。
--- unit_search_distance :: uint (可选)：搜索单位的半径。搜索区域以命令的目标为中心。
--- 返回值
--- 实际派出的单位数量。如果没有足够的单位可用，则可能少于
--- count
--- 。
---@return integer count
---@param command table? command :: Command  
unit_count :: uint: 接受该命令的单位数量。  
force :: ForceSpecification (可选): 该命令要下达给的单位的势力。如果未指定，则使用敌方势力。  
unit_search_distance :: uint (可选): 搜索单位的半径。搜索区域以命令的目的地为中心。
function LuaSurface:set_multi_command(command) end

--- 在指定位置设置地块。自动修正被修改地块周围的边缘。
--- 参数
--- tiles :: array of Tile：每个 Tile 是一个表：
--- name :: string
--- position :: Position
--- correct_tiles :: boolean (可选)：如果为
--- false
--- ，则不对被修改的地块执行修正逻辑。默认为
--- true
--- 。
--- 注意： 建议对所有要更改的地块一次性调用此方法，而不是对每个地块单独调用。由于地块修正在每一步之后都会使用，逐个调用可能导致地块修正逻辑重做部分更改，而且性能开销也大得多。
---@param correct_tiles boolean? 如果为 `false`，则不对改变的地块执行校正逻辑。默认为 `true`。
---@param tiles table[] 每个 Tile 是一个表:   
name :: string  
position :: Position
function LuaSurface:set_tiles(correct_tiles, tiles) end

--- 在给定位置为中心的地面上洒出物品。
--- 参数
--- position :: Position：洒出区域的中心
--- items :: ItemStackSpecification：要洒出的物品
--- enable_looted :: boolean (可选)：为 true 时，每个创建的物品都将被标记上 LuaEntity::to_be_looted 标志。
--- force :: LuaForce 或 string (可选)：提供时（且不为
--- nil
--- ），物品将被该势力标记为拆除。
--- allow_belts :: boolean (可选)：物品是否可以洒到传送带上。默认为
--- true
--- 。
---@param allow_belts boolean? 物品是否可以散落到传送带(belt)上。默认为 `true`。
---@param enable_looted boolean? 为 true 时，每个创建的物品都会被标记上 LuaEntity::to_be_looted 标志。
---@param force LuaForce | string? 当提供（且不为 `nil`）时，物品将被标记为由该势力拆除(deconstruction)。
---@param items table 要散落的物品
---@param position table 散落的中心位置
function LuaSurface:spill_item_stack(allow_belts, enable_looted, force, items, position) end

--- 放置升级请求。
--- 参数
--- 包含以下字段的表：
--- area :: BoundingBox：要标记升级的区域。
--- force :: ForceSpecification：其机器人应执行升级的势力。
--- player :: PlayerSpecification (可选)：如果存在，则将其设为 last_user 的玩家。
--- skip_fog_of_war :: boolean (可选)：是否跳过战争迷雾覆盖的区块。
--- item :: LuaItemStack：要使用的升级物品。
---@param area table? area :: BoundingBox: 要标记为升级(upgrade)的区域。  
force :: ForceSpecification: 执行升级的机器人(bot)所属的势力。  
player :: PlayerSpecification (可选): 如果有的话，将其设置为 last_user 的玩家。  
skip_fog_of_war :: boolean (可选): 是否跳过被战争迷雾覆盖的区块。  
item :: LuaItemStack: 要使用的升级物品。
function LuaSurface:upgrade_area(area) end

--- 一个研究项目。
---@class LuaTechnology
---@field effects table[] (只读) 研究此科技时应用的效果。
---@field enabled boolean 此科技是否可以研究？
---@field force LuaForce (只读) 此科技所属的势力。
---@field help string 此对象支持的所有方法和属性。
---@field level integer 此科技的当前等级。对于基于等级的科技，写入此值等同于将科技研究到上一个等级。写入等级会将 LuaTechnology::enabled 设置为 true
---@field localised_description table (只读)
---@field localised_name table (只读) 此科技的本地化名称。
---@field name string (只读) 此科技的名称。
---@field order string (只读) 此原型的排序字符串。
---@field prerequisites table<string, LuaTechnology> (只读) 此科技的前置科技。结果将科技名称映射到 LuaTechnology 对象。
---@field prototype LuaTechnologyPrototype (只读) 此科技的原型。
---@field research_unit_count integer (只读) 此科技所需的研究单位数量。 另见 LuaTechnology::research_unit_ingredients
---@field research_unit_count_formula string (只读) 此无限研究所使用的数量公式；如果这不是无限研究，则为 nil。
---@field research_unit_energy number (只读) 完成一个研究单位所需的能量。
---@field research_unit_ingredients table[] (只读) 实验室研究此科技所需的原料。 另见 LuaTechnology::research_unit_count
---@field researched boolean 此科技是否已研究？从 false 切换到 true 将触发科技进阶加成；从 true 切换到 false 将撤销它们。
---@field upgrade boolean (只读) 这是升级型研究吗？
---@field valid boolean (只读) 此对象是否有效？
---@field visible_when_disabled boolean 即使此科技被禁用，它是否也会在研究 GUI 中可见。
LuaTechnology = {}

--- 从其原型重新加载此科技。
function LuaTechnology:reload(...) end

--- 一个科技原型。
---@class LuaTechnologyPrototype
---@field effects table[] (只读) 研究此科技时应用的效果。
---@field enabled boolean (只读) 此科技原型默认是否启用（在游戏开始时启用）。
---@field help string 此对象支持的所有方法和属性。
---@field hidden boolean (只读) 此科技原型是否隐藏。
---@field level integer (只读) 此研究的等级。
---@field localised_description table (只读)
---@field localised_name table (只读) 此科技的本地化名称。
---@field max_level integer (只读) 此研究的最大等级。
---@field name string (只读) 此科技的名称。
---@field order string (只读) 此原型的排序字符串。
---@field prerequisites table<string, LuaTechnologyPrototype> (只读) 此科技的前置科技。结果将科技名称映射到 LuaTechnologyPrototype 对象。
---@field research_unit_count integer (只读) 此科技所需的研究单位数量。 另见 LuaTechnologyPrototype::research_unit_ingredients
---@field research_unit_count_formula string (只读) 此无限研究所使用的数量公式；如果这不是无限研究，则为 nil。
---@field research_unit_energy number (只读) 完成一个研究单位所需的能量。
---@field research_unit_ingredients table[] (只读) 实验室研究此科技所需的原料。 另见 LuaTechnologyPrototype::research_unit_count
---@field upgrade boolean (只读) 此科技原型是否是某些其他科技的升级。
---@field valid boolean (只读) 此对象是否有效？
---@field visible_when_disabled boolean (只读) 即使此科技被禁用，它是否也会在研究 GUI 中可见。
LuaTechnologyPrototype = {}

--- 地图上的单个「方块」。
---@class LuaTile
---@field help string 此对象支持的所有方法和属性。
---@field hidden_tile string (只读)
---@field name string (只读) 此地块的原型名称。例如 "sand-3" 或 "grass-2" 。
---@field position table (只读) 此地块引用的位置。
---@field prototype LuaTilePrototype (只读)
---@field valid boolean (只读) 此对象是否有效？
LuaTile = {}

--- 如果已安排拆除则取消拆除，否则不做任何事。
--- 参数
--- force :: ForceSpecification：下达拆除指令的势力。
--- player :: PlayerSpecification (可选)：如果存在，则将其设为 last_user 的玩家。
---@param force table 下达拆除（deconstruction）命令的势力。
---@param player table? 要将其设置为 last_user 的玩家（如果有）。
function LuaTile:cancel_deconstruction(force, player) end

--- 什么类型的事物可以与此地块碰撞。
--- 参数
--- layer :: CollisionMaskLayer
--- 示例
--- 检查角色是否会与地块碰撞。
--- game.player.print(tostring(game.player.surface.get_tile(1,聽1).collides_with("player-layer")))
---@return boolean ok
---@param layer table
function LuaTile:collides_with(layer) end

--- 命令给定势力拆除此地块。
--- 参数
--- force :: ForceSpecification：其机器人应执行拆除的势力。
--- player :: PlayerSpecification (可选)：如果存在，则将其设为 last_user 的玩家。
--- 返回值
--- 如果存在，则返回所创建的可拆除地块代理；否则为
--- nil
--- 。
---@return LuaEntity entity
---@param force table 其机器人（robots）应执行拆除（deconstruction）的势力。
---@param player table? 要将其设置为 last_user 的玩家（如果有）。
function LuaTile:order_deconstruction(force, player) end

--- 地块的原型。
---@class LuaTilePrototype
---@field allowed_neighbors table<string, LuaTilePrototype> (只读)
---@field automatic_neighbors boolean (只读)
---@field autoplace_specification table (只读) 此原型的自动放置规范。如果没有则为 nil 。
---@field can_be_part_of_blueprint boolean (只读) 如果无论是否能够建造，此地块都不允许出现在蓝图中，则为 false。
---@field collision_mask table<string, boolean> (只读) 此地块使用的碰撞掩码。每个条目的布尔值没有意义，将始终为 true 。 注意： 这是此地块使用的碰撞掩码的字典，以便快速查找任何值。
---@field decorative_removal_probability number (只读) 生成此地块时，装饰物实体被从该地块顶部移除的概率。
---@field emissions_per_second number (只读) 此地块每 tick 将吸收的污染排放量。
---@field help string 此对象支持的所有方法和属性。
---@field items_to_place_this table[] (只读) 放置后会产生此地块的物品。这是一个以物品原型名称为索引的字典。
---@field layer integer (只读)
---@field localised_description table (只读)
---@field localised_name table (只读)
---@field map_color table (只读)
---@field mineable_properties table (只读) 它是一个表： minable :: boolean：此地块到底是否可开采？ miningtime :: double：开采一个地块所需的能量。 miningparticle :: string (可选)：开采此地块时产生的粒子原型名称。仅当此地块开采时产生任何粒子时才存在。 products :: array of Product：开采此地块获得的产物。
---@field name string (只读) 此原型的名称。
---@field needs_correction boolean (只读) 当地块在世界中生成时，此地块是否需要应用修正逻辑。
---@field next_direction LuaTilePrototype (只读) 此地块的下一个方向，或 nil ——当地块有多个方向时使用（例如危险混凝土）。
---@field order string (只读) 此原型的排序字符串。
---@field valid boolean (只读) 此对象是否有效？
---@field vehicle_friction_modifier number (只读)
---@field walking_speed_modifier number (只读)
LuaTilePrototype = {}

--- 一列火车。火车是一系列相连的机车车辆——火车头和车厢。
---@class LuaTrain
---@field back_rail LuaEntity (只读) 火车后端的铁轨，可能为 nil 。
---@field back_stock LuaEntity (只读) 此火车的后端车辆，或 nil 。
---@field cargo_wagons LuaEntity[] (只读) 火车包含的货运车厢。
---@field carriages LuaEntity[] (只读) 组成火车的机车车辆。
---@field fluid_wagons LuaEntity[] (只读) 火车包含的流体车厢。
---@field front_rail LuaEntity (只读) 火车前端的铁轨，可能为 nil 。
---@field front_stock LuaEntity (只读) 此火车的前端车辆，或 nil 。
---@field has_path boolean (只读) 此火车是否有路径。
---@field help string 此对象支持的所有方法和属性。
---@field id integer (只读) 唯一的火车 ID。
---@field kill_count integer (只读) 此火车的总击杀数。
---@field killed_players table<integer, integer> (只读) 被此火车击杀的玩家。 键是玩家索引，值是该火车击杀该玩家的次数。
---@field locomotives table<string, LuaEntity[]> (只读) 火车头数组。结果是两个数组，以 "front_movers" 和 "back_movers" 为索引，包含火车头。例如 {front_movers={loco1, loco2}, back_movers={loco3}} 。
---@field manual_mode boolean 当为 true 时，火车由玩家或脚本显式控制。当为 false 时，火车按时刻表自主移动。
---@field max_backward_speed number (只读) 向后移动时的当前最大速度，取决于火车头原型和燃料。
---@field max_forward_speed number (只读) 向前移动时的当前最大速度，取决于火车头原型和燃料。
---@field passengers LuaPlayer[] (只读) 火车上的玩家乘客。 注意： 这不是用玩家索引索引的。请参见每个玩家实例上的 LuaPlayer::index 获取玩家索引。
---@field path LuaRailPath (只读) 此火车正在使用的路径，如果没有则为 nil 。
---@field path_end_rail LuaEntity (只读) 此火车当前正在寻路前往的目标铁轨，或 nil 。
---@field path_end_stop LuaEntity (只读) 此火车当前正在寻路前往的目标火车站，或 nil 。
---@field rail_direction_from_back_rail defines.rail_direction (只读)
---@field rail_direction_from_front_rail defines.rail_direction (只读)
---@field riding_state table (只读) 此火车的乘坐状态。
---@field schedule table 火车当前的时刻表。设置为 nil 以清除。 注意： 不能通过修改返回的表来更改时刻表。相反，必须通过给此属性赋一个新表来进行更改。
---@field signal LuaEntity (只读) 此火车正在到达或等待的信号，如果没有则为 nil 。
---@field speed number 当前速度。 注意： 更改火车的速度可能是危险的操作，因为火车使用速度进行制动距离等的内部计算。
---@field state defines.train_state (只读) 此火车当前的状态。
---@field station LuaEntity (只读) 此火车停靠的火车站，或 nil 。
---@field valid boolean (只读) 此对象是否有效？
---@field weight number (只读) 此火车的重量。
LuaTrain = {}

--- 清除此火车中的所有流体。
function LuaTrain:clear_fluids_inside(...) end

--- 清除此火车中的所有物品。
function LuaTrain:clear_items_inside(...) end

--- 获取火车物品栏的映射。
--- 返回值
--- 按物品名称索引的数量。
---@return table<string, integer> count
function LuaTrain:get_contents(...) end

--- 获取火车流体物品栏的映射。
--- 返回值
--- 按流体名称索引的数量。
---@return table<string, number> count
function LuaTrain:get_fluid_contents(...) end

--- 获取火车中存储的特定流体的量。
--- 参数
--- fluid :: string (可选)：要计数的流体名称。如果未给出，则统计所有流体。
---@return number count
---@param fluid string? 要统计的流体名称。如果未给出，则统计所有流体。
function LuaTrain:get_fluid_count(fluid) end

--- 获取火车中存储的特定物品的量。
--- 参数
--- item :: string (可选)：要计数的物品名称。如果未给出，则统计所有物品。
---@return integer count
---@param item string? 要统计的物品名称。如果未给出，则统计所有物品。
function LuaTrain:get_item_count(item) end

--- 获取火车下方的所有铁轨。
---@return LuaEntity[] entity
function LuaTrain:get_rails(...) end

--- 前往火车时刻表中指定索引的车站。
--- 参数
--- index :: uint
---@param index integer
function LuaTrain:go_to_station(index) end

--- 向火车插入一个物品堆。
--- 参数
--- stack :: ItemStackSpecification
---@param stack table
function LuaTrain:insert(stack) end

--- 将给定流体插入此火车中第一个可用位置。
--- 参数
--- 返回值
--- 插入的量。
---@return number count
---@param undefined any
function LuaTrain:insert_fluid(undefined) end

--- 检查路径是否无效，如果无效则尝试重新寻路。
--- 参数
--- force :: boolean (可选)：无论当前路径是否有效，都强制火车重新寻路。
--- 返回值
--- 重新寻路尝试后火车是否有路径。
---@return boolean ok
---@param force boolean? 无论当前路径是否有效，都强制列车重新寻路(re-path)。
function LuaTrain:recalculate_path(force) end

--- 从火车中移除一些流体。
--- 参数
--- fluid: 一个包含 type 和 amount 的表
--- 返回值
--- 实际移除的流体量。
---@return number count
---@param fluid table 包含 type 和 amount 的表
function LuaTrain:remove_fluid(fluid) end

--- 从火车中移除一些物品。
--- 参数
--- stack :: ItemStackSpecification：要移除的物品数量和类型
--- 返回值
--- 实际移除的物品数量。
---@return integer count
---@param stack table 要移除的物品数量与类型
function LuaTrain:remove_item(stack) end

--- 火车站的控制行为。
---@class LuaTrainStopControlBehavior
---@field circuit_condition table 电路条件。 注意： condition 可以为 nil 以清除电路条件。 示例 让一个实体在收到大于 4 的链式信号电路信号时处于活动状态（例如灯点亮）。 a_behavior.circuit_condition聽=聽{condition={comparator="&gt;", 聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽first_signal={type="item",聽name="rail-chain-signal"}, 聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽constant=4}}
---@field connect_to_logistic_network boolean 如果此实体应连接到物流网络，则为 true 。
---@field disabled boolean (只读) 实体当前是否因控制行为而被禁用。
---@field enable_disable boolean 如果火车站通过电路网络启用/禁用，则为 true 。
---@field entity LuaEntity (只读) 此控制行为所属的实体。
---@field help string 此对象支持的所有方法和属性。
---@field logistic_condition table 物流条件。 注意： condition 可以为 nil 以清除物流条件。 示例 让一个实体在它所连接的物流网络拥有超过 4 个链式信号时处于活动状态（例如灯点亮）。 a_behavior.logistic_condition聽=聽{condition={comparator="&gt;", 聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽first_signal={type="item",聽name="rail-chain-signal"}, 聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽constant=4}}
---@field read_from_train boolean 如果火车站应将火车内容发送到电路网络，则为 true 。
---@field read_stopped_train boolean 如果火车站应将停靠的火车 ID 发送到电路网络，则为 true 。
---@field send_to_train boolean 如果火车站应将电路网络内容发送给火车使用，则为 true 。
---@field stopped_train_signal table 使用发送火车 ID 选项时将发送的信号。
---@field type defines.control_behavior.type (只读) 此控制行为的具体类型。
---@field valid boolean (只读) 此对象是否有效？
LuaTrainStopControlBehavior = {}

--- 参数
--- wire :: defines.wire_type：与此实体相连的网络的电线颜色。
--- circuit_connector :: defines.circuit_connector_id (可选)：要为其获取电路网络的连接器。
--- 对于拥有多个电路网络连接器的实体必须指定。
--- 返回值
--- 电路网络或 nil。
---@return LuaCircuitNetwork result
---@param circuit_connector defines.circuit_connector_id? 要获取其电路网络的连接器。
对于拥有多个电路网络连接器的实体，必须指定此项。
---@param wire defines.wire_type 连接到此实体的网络的导线颜色。
function LuaTrainStopControlBehavior:get_circuit_network(circuit_connector, wire) end

--- 传送带的控制行为。
---@class LuaTransportBeltControlBehavior
---@field circuit_condition table 电路条件。 注意： condition 可以为 nil 以清除电路条件。 示例 让一个实体在收到大于 4 的链式信号电路信号时处于活动状态（例如灯点亮）。 a_behavior.circuit_condition聽=聽{condition={comparator="&gt;", 聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽first_signal={type="item",聽name="rail-chain-signal"}, 聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽constant=4}}
---@field connect_to_logistic_network boolean 如果此实体应连接到物流网络，则为 true 。
---@field disabled boolean (只读) 实体当前是否因控制行为而被禁用。
---@field enable_disable boolean 传送带是否将根据电路网络启用/禁用。
---@field entity LuaEntity (只读) 此控制行为所属的实体。
---@field help string 此对象支持的所有方法和属性。
---@field logistic_condition table 物流条件。 注意： condition 可以为 nil 以清除物流条件。 示例 让一个实体在它所连接的物流网络拥有超过 4 个链式信号时处于活动状态（例如灯点亮）。 a_behavior.logistic_condition聽=聽{condition={comparator="&gt;", 聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽first_signal={type="item",聽name="rail-chain-signal"}, 聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽聽constant=4}}
---@field read_contents boolean 传送带是否将读取内容并将其发送到电路网络。
---@field read_contents_mode defines.control_behavior.transport_belt.content_read_mode 传送带的读取模式。
---@field type defines.control_behavior.type (只读) 此控制行为的具体类型。
---@field valid boolean (只读) 此对象是否有效？
LuaTransportBeltControlBehavior = {}

--- 参数
--- wire :: defines.wire_type：与此实体相连的网络的电线颜色。
--- circuit_connector :: defines.circuit_connector_id (可选)：要为其获取电路网络的连接器。
--- 对于拥有多个电路网络连接器的实体必须指定。
--- 返回值
--- 电路网络或 nil。
---@return LuaCircuitNetwork result
---@param circuit_connector defines.circuit_connector_id? 要获取其电路网络的连接器。
对于拥有多个电路网络连接器的实体，必须指定此项。
---@param wire defines.wire_type 连接到此实体的网络的导线颜色。
function LuaTransportBeltControlBehavior:get_circuit_network(circuit_connector, wire) end

--- 传送带上的一条线。
---@class LuaTransportLine
---@field help string 此对象支持的所有方法和属性。
---@field input_lines LuaTransportLine[] (只读) 为此传送线供料的传送线；如果没有则为空表。
---@field _operator___ LuaItemStack (只读) 索引运算符。
---@field _operator__ integer (只读) 获取此传送线上的物品数量。
---@field output_lines LuaTransportLine[] (只读) 此传送线向其输出物品的传送线；如果没有则为空表。
---@field owner LuaEntity (只读) 此传送线所属的实体。
---@field valid boolean (只读) 此对象是否有效？
LuaTransportLine = {}

--- 能否在给定位置插入物品？
--- 参数
--- position :: float：在哪里插入物品。
---@return boolean ok
---@param position number 插入物品的位置。
function LuaTransportLine:can_insert_at(position) end

--- 能否在此线的后端插入物品？
---@return boolean ok
function LuaTransportLine:can_insert_at_back(...) end

--- 从此传送线移除所有物品。
function LuaTransportLine:clear(...) end

--- 获取此线上所有物品的数量。
--- 返回值
--- 按物品名称索引的数量。
--- 另见
--- LuaInventory::get_contents
---@return table<string, integer> count
function LuaTransportLine:get_contents(...) end

--- 统计此线上部分或全部物品。
--- 参数
--- item :: string (可选)：要计数的物品原型名称。如果未指定，则统计所有物品。
--- 另见
--- LuaInventory::get_item_count
---@return integer count
---@param item string? 要计数的物品的原型名称。如果未指定，则统计所有物品。
function LuaTransportLine:get_item_count(item) end

--- 在给定位置插入物品。
--- 参数
--- position :: float：在线的哪个位置插入物品。
--- items :: ItemStackSpecification：要插入的物品。
--- 返回值
--- 物品是否成功插入？
---@return boolean ok
---@param items table 要插入的物品。
---@param position number 在传送线上插入物品的位置。
function LuaTransportLine:insert_at(items, position) end

--- 在此线的后端插入物品。
--- 参数
--- items :: ItemStackSpecification
--- 返回值
--- 物品是否成功插入？
---@return boolean ok
---@param items table
function LuaTransportLine:insert_at_back(items) end

--- 返回此线关联的内部传送线是否与另一条线的关联内部传送线相同。
--- 参数
--- other :: LuaTransportLine
--- 注意： 即使 LuaTransportLine::owner 不同（因此
--- this == other
--- 为 false），也可能返回 true，因为内部传送线可以跨越多个地块。
---@return boolean ok
---@param other LuaTransportLine
function LuaTransportLine:line_equals(other) end

--- 从此线移除一些物品。
--- 参数
--- items :: ItemStackSpecification：要移除的物品。
--- 返回值
--- 实际移除的物品数量。
---@return integer count
---@param items table 要移除的物品。
function LuaTransportLine:remove_item(items) end

--- 一组一起移动和攻击的单位集合。引擎会创建自主单位组来攻击受污染的区域。脚本也可以创建和控制此类单位组。单位组可以像普通单位一样接受命令。
---@class LuaUnitGroup
---@field force LuaForce (只读) 此单位组的势力。
---@field group_number integer (只读) 此单位组的组编号。
---@field help string 此对象支持的所有方法和属性。
---@field members LuaEntity[] (只读) 此单位组的成员。
---@field position table (只读) 单位组的位置。根据单位组状态的不同，其含义也不同。当单位组在集结时，位置是集结地点。当单位组在移动时，位置是其成员沿路径的预期位置。当单位组在攻击时，位置是其成员的平均位置。
---@field state defines.group_state (只读) 此单位组是在集结、移动还是攻击。
---@field surface LuaSurface (只读) 此单位组所在的地表。
---@field valid boolean (只读) 此对象是否有效？
LuaUnitGroup = {}

--- 让一个单位成为此单位组的成员。与向该单位发出包含此单位组的
--- group_command
--- 命令效果相同。
--- 参数
--- unit :: LuaEntity
--- 注意： 成员必须与单位组具有相同的势力。
---@param unit LuaEntity
function LuaUnitGroup:add_member(unit) end

--- 解散此单位组。其成员不会被销毁，它们只会与此单位组解除关联。
function LuaUnitGroup:destroy(...) end

--- 让此单位组自主行动。自主单位组将自动攻击受污染的区域。
function LuaUnitGroup:set_autonomous(...) end

--- 给此单位组下达命令。
--- 参数
--- command :: Command
--- 另见
--- LuaEntity::set_command
---@param command table
function LuaUnitGroup:set_command(command) end

--- 即使某些成员尚未到达，也让单位组开始移动。
function LuaUnitGroup:start_moving(...) end

--- 虚拟信号的原型。
---@class LuaVirtualSignalPrototype
---@field help string 此对象支持的所有方法和属性。
---@field localised_description table (只读)
---@field localised_name table (只读)
---@field name string (只读) 此原型的名称。
---@field order string (只读) 此原型的排序字符串。
---@field special boolean (只读) 如果这是一个特殊信号
---@field subgroup LuaGroup (只读)
---@field valid boolean (只读) 此对象是否有效？
LuaVirtualSignalPrototype = {}

--- 墙的控制行为。
---@class LuaWallControlBehavior
---@field circuit_condition table 电路条件。
---@field entity LuaEntity (只读) 此控制行为所属的实体。
---@field help string 此对象支持的所有方法和属性。
---@field open_gate boolean
---@field output_signal table
---@field read_sensor boolean
---@field type defines.control_behavior.type (只读) 此控制行为的具体类型。
---@field valid boolean (只读) 此对象是否有效？
LuaWallControlBehavior = {}

--- 参数
--- wire :: defines.wire_type：与此实体相连的网络的电线颜色。
--- circuit_connector :: defines.circuit_connector_id (可选)：要为其获取电路网络的连接器。
--- 对于拥有多个电路网络连接器的实体必须指定。
--- 返回值
--- 电路网络或 nil。
---@return LuaCircuitNetwork result
---@param circuit_connector defines.circuit_connector_id? 要获取其电路网络的连接器。
对于拥有多个电路网络连接器的实体，必须指定此项。
---@param wire defines.wire_type 连接到此实体的网络的导线颜色。
function LuaWallControlBehavior:get_circuit_network(circuit_connector, wire) end
