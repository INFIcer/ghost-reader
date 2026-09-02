
---local defines=require("defines")

---64 位无符号整数。可能的值介于00 到 1 之间18 446 744 073 709 551 615。
---
---由于 Lua 5.2 只使用 double 类型，任何请求 double 类型的 APIuint64都会将给定的 double 类型向下取整。
---@class uint64

---@alias RegistrationTarget LuaEntity | LuaEquipment | LuaEquipmentGrid | LuaItem | LuaLogisticCell | LuaLogisticNetwork | LuaLogisticSection | LuaPermissionGroup | LuaPlanet | LuaPlayer | LuaRailPath | LuaRenderObject | LuaSpacePlatform | LuaSurface | LuaTrain | LuaCommandable | LuaCustomChartTag | LuaGuiElement | LuaCargoHatch | LuaSchedule | LuaTerritory | LuaSegmentedUnit | LuaElectricNetwork | LuaElectricSubNetwork | LuaForce

--- 注册一个对象，以便在对象被销毁后调用on_object_destroyed函数。
---
--- 一旦对象被注册，它就会一直保持注册状态，直至实际被销毁，即使经历了保存/加载循环也是如此。这种注册在所有模组中都是全局性的，这意味着一旦某个模组注册了一个对象，所有监听on_object_destroyed事件的模组都会在对象被销毁时接收到该事件。即使多次注册同一个对象，销毁事件也只会触发一次，并且会返回相同的注册编号。
---
--- 根据给定对象被销毁的时间，on_object_destroyed事件会在当前tick结束时触发，或者在下一个tick结束时触发。
---@return uint64 register_number          注册号。它用于在on_object_destroyed事件中识别对象。
---@return uint64 useful_id                对象是否有标识符，则该标识符为对象的有效标识符0。此标识符特定于对象类型，例如，对于火车，其值为LuaTrain::id。
---@return defines.target_type target_type 目标对象的类型。
---@param _object RegistrationTarget
function LuaBootstrap:register_on_object_destroyed(_object) end
