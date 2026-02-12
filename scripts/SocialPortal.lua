print("(Loaded) Social Portal Script for GrowSoft")

onPlayerActionCallback(function(world, player, data)

    local action = data["action"]
    
    if action == "friends" then

        player:onDialogRequest(
                "set_bg_color|170,175,180,255|\n" ..
                "set_border_color|255,192,203,255|\n" ..
                "add_spacer|small|\n" ..
                "add_label_with_icon|big|`wGrowlush Social Portal|left|1366|\n" ..
                "add_spacer|small|\n" ..
                "set_custom_spacing|x:5;y:10|\n" ..
                "add_custom_button|open_friends|image:interface/server_1981/socialportal_friends.rttex;image_size:400,260;width:0.19;|\n" ..
                "add_custom_button|open_guild|image:interface/server_1981/socialportal_guild.rttex;image_size:400,260;width:0.19;|\n" ..
                "add_custom_button|open_events|image:interface/server_1981/socialportal_events.rttex;image_size:400,260;width:0.19;|\n" ..
                "add_custom_button|open_settings|image:interface/server_1981/socialportal_settings.rttex;image_size:400,260;width:0.19;|\n" ..
                "add_custom_button|open_roles|image:interface/server_1981/socialportal_roles.rttex;image_size:400,260;width:0.19;|\n" ..
                "add_custom_button|open_pets|image:interface/server_1981/socialportal_pets.rttex;image_size:400,260;width:0.19;|\n" ..
                "add_custom_button|open_opc|image:interface/server_1981/socialportal_OPC.rttex;image_size:400,260;width:0.19;|\n" ..
                "add_custom_button|open_convert|image:interface/server_1981/socialportal_convert.rttex;image_size:400,260;width:0.19;|\n" ..
                "add_custom_button|open_sellfish|image:interface/server_1981/socialportal_fish.rttex;image_size:400,260;width:0.19;|\n" ..
                "add_custom_break|\n" ..
                "add_spacer|small|\n" ..
                "add_spacer|small|\n" ..
                "add_button|close_button|`wClose Social Portal|0|0|\n" ..
                "end_dialog|socialPortal|||\n" ..
                "add_custom_break|\n" ..
                "add_label_with_icon|small||left|o|\n"
        )

        return true
    end

    return false
end)