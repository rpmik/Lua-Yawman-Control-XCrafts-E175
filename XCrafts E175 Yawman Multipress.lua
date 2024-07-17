--[[
 XCrafts E175 mapping for the Yawman Arrow By Ryan Mikulovsky, CC0 1.0.
 
 Inspired by Yawman's mapping for the MSFS PMDG 777.
 Thanks for Thomas Nield for suggesting looking into Lua for better controller support in XP12. Button numbers and variable names came from Thomas.
 
 See Thomas' video and access example Lua scripts at https://www.youtube.com/watch?v=x8SMg33RRQ4
 
 Repository at https://github.com/rpmik/Lua-Yawman-Control-XCrafts-E175
]]
-- use local to prevent other unknown Lua scripts from overwriting variables (or vice versa)
local STICK_X = 0 
local STICK_Y = 1
local POLE_RIGHT = 2 
local POLE_LEFT = 3
local RUDDER = 4
local SLIDER_LEFT = 5
local SLIDER_RIGHT = 6 
local POV_UP = 0
local POV_RIGHT = 2
local POV_DOWN = 4
local POV_LEFT = 6
local THUMBSTICK_CLK = 8
local SIXPACK_1 = 9
local SIXPACK_2 = 10
local SIXPACK_3 = 11
local SIXPACK_4 = 12
local SIXPACK_5 = 13
local SIXPACK_6 = 14
local POV_CENTER = 15
local RIGHT_BUMPER = 16
local DPAD_CENTER = 17
local LEFT_BUMPER = 18
local WHEEL_DOWN = 19
local WHEEL_UP = 20
local DPAD_UP = 21
local DPAD_LEFT = 22
local DPAD_DOWN = 23
local DPAD_RIGHT = 24

-- Logic states to keep button assignments sane
local PAUSE_STATE = false
local STILL_PRESSED = false -- track presses for everything
local MULTI_SIXPACK_PRESSED = false -- track presses for only the six pack where there's multiple six pack buttons involved
local DPAD_PRESSED = false

local CHASE_VIEW = false

local FRAME_COUNT = 0.0
local GoFasterFrameRate = 0.0
local PauseIncrementFrameCount = 0.0

-- If aircraft's interactive Command increment is not continuous, use framerate to meter incrementing
--[[
 The XCrafts E-175 is a bit different from other aircraft in that a command has to be issued repeatedly to increment. 
 So one cannot use a button assignment and hold that button down to increment in a reasonable manner. It'll increment
 once and stop until you press the button again. So we have to use command_once upon button press and hold. But this means the
 command will be called EVERY frame while a button is held, which causes incrementing at frame rate speeds. So we must meter
 the number of times the command for incrementing is called for so humans can increment in a manner they can predict.
]]
function meterE175Interaction(strCommandName1, strCommandName2, floatSeconds)
		-- Set metering based on current frame rate
		DataRef("FrameRatePeriod","sim/operation/misc/frame_rate_period","writable")
		CurFrame = FRAME_COUNT
		
		if not DPAD_PRESSED then
			FrameRate = 1/FrameRatePeriod
			-- Roughly calculate how many frames to wait before incrementing based on floatSeconds
			GoFasterFrameRate = (floatSeconds * FrameRate) + CurFrame -- start five seconds of slow increments
		end

		if CurFrame < GoFasterFrameRate then
			if not DPAD_PRESSED then
				command_once(strCommandName1)
				-- calculate frame to wait until continuing
				-- if floatSeconds is 2 then we'll wait around 1 second before continuing so as to allow a single standalone increment
				PauseIncrementFrameCount = ((floatSeconds/2) * FrameRate) + CurFrame
			else
				-- wait a beat with PauseIncrementFrameCount then continue
				if (CurFrame > PauseIncrementFrameCount) and (CurFrame % 5) == 0 then
					command_once(strCommandName1)
				end
			end
		elseif CurFrame >= GoFasterFrameRate and DPAD_PRESSED then
			-- If current frame is divisible by five then issue a command -- helps to delay the command in a regular interval
			if (CurFrame %5) == 0 then
				command_once(strCommandName2)
			end
		end			
end


function multipressXCraftsE175_buttons() 
    -- if aircraft is an Embraer E-175 then procede
    if PLANE_ICAO == "E175" then 
        FRAME_COUNT = FRAME_COUNT + 1.0  
		

		-- Base Config buttons that should almost always get reassigned except during a press
        if not STILL_PRESSED then -- avoid overwriting assignments during other activity
			set_button_assignment(DPAD_UP,"sim/none/none")
			set_button_assignment(DPAD_DOWN,"sim/none/none")
			set_button_assignment(DPAD_LEFT,"sim/general/zoom_out_fast")
			set_button_assignment(DPAD_RIGHT,"sim/general/zoom_in_fast")
			set_button_assignment(WHEEL_UP, "sim/none/none")
			set_button_assignment(WHEEL_DOWN, "sim/none/none")
			set_button_assignment(LEFT_BUMPER, "sim/none/none") -- multifunction
			set_button_assignment(RIGHT_BUMPER, "sim/none/none") -- multifunction
			set_button_assignment(SIXPACK_1,"sim/none/none")
			set_button_assignment(SIXPACK_2,"sim/flight_controls/brakes_regular")
			set_button_assignment(SIXPACK_3,"sim/none/none")		
			set_button_assignment(SIXPACK_4,"sim/none/none")
			set_button_assignment(SIXPACK_5,"sim/none/none")
			set_button_assignment(SIXPACK_6,"sim/none/none")			
			set_button_assignment(POV_UP,"sim/flight_controls/pitch_trim_up")
			set_button_assignment(POV_DOWN,"sim/flight_controls/pitch_trim_down")
			set_button_assignment(POV_LEFT,"sim/view/glance_left")
			set_button_assignment(POV_RIGHT,"sim/view/glance_right")
			set_button_assignment(POV_CENTER,"sim/view/default_view")

        end 
        
        -- Get button status
    
        right_bumper_pressed = button(RIGHT_BUMPER)
        left_bumper_pressed = button(LEFT_BUMPER)
        
        sp1_pressed = button(SIXPACK_1)
        sp2_pressed = button(SIXPACK_2)
        sp3_pressed = button(SIXPACK_3)
		sp4_pressed = button(SIXPACK_4)
		sp5_pressed = button(SIXPACK_5)
		sp6_pressed = button(SIXPACK_6)
		
		pov_up_pressed = button(POV_UP)
		pov_down_pressed = button(POV_DOWN)
		
		dpad_up_pressed = button(DPAD_UP)
		dpad_center_pressed = button(DPAD_CENTER)
		dpad_down_pressed = button(DPAD_DOWN)
		dpad_left_pressed = button(DPAD_LEFT)
		dpad_right_pressed = button(DPAD_RIGHT)
		
-- Start expanded control logic

		if dpad_center_pressed and not CHASE_VIEW and not STILL_PRESSED then
			command_once("sim/view/chase")
			CHASE_VIEW = true
			STILL_PRESSED = true
		end
	
		if dpad_center_pressed and CHASE_VIEW and not STILL_PRESSED then
			command_once("sim/view/default_view")
			CHASE_VIEW = false
			STILL_PRESSED = true
		end

-- Auto pilot engage A 
		
		if right_bumper_pressed and not dpad_up_pressed and not STILL_PRESSED then
			command_once("XCrafts/APYD_Toggle")
			STILL_PRESSED = true
		
		end
		
-- autopilot control
	
		if sp1_pressed then
			if dpad_up_pressed then
				meterE175Interaction("XCrafts/ERJ/SPD_up_1", "XCrafts/ERJ/SPD_up_10", 2.0) -- at around two seconds, use larger increment
				DPAD_PRESSED = true
			elseif dpad_down_pressed then
				meterE175Interaction("XCrafts/ERJ/SPD_dn_1", "XCrafts/ERJ/SPD_dn_10", 2.0)
				DPAD_PRESSED = true
			end
			
			if not STILL_PRESSED then -- Do not constantly set the button assignment every frame
				set_button_assignment(RIGHT_BUMPER,"XCrafts/ERJ/AutoThrottle")
				set_button_assignment(DPAD_RIGHT,"XCrafts/ERJ/FLCH")
			end

		-- Pause Simulation
			if sp2_pressed and sp3_pressed and not MULTI_SIXPACK_PRESSED then
				command_once("sim/operation/pause_toggle")
				MULTI_SIXPACK_PRESSED = true
			else
				STILL_PRESSED = true
			end
		end
		
		if sp2_pressed then
			-- Flight director isn't very useful on the B742, just command bars, so will make this roll mode INS, which is basically the real flight directory.
			if not STILL_PRESSED then -- Do not constantly set the button assignment every frame
				set_button_assignment(RIGHT_BUMPER,"XCrafts/ERJ/fdir_toggle")
				set_button_assignment(DPAD_RIGHT,"XCrafts/ERJ/LNAV")
				set_button_assignment(DPAD_LEFT,"sim/autopilot/NAV") -- built-in XP12 command
				set_button_assignment(DPAD_DOWN,"XCrafts/ERJ/APPCH")
				set_button_assignment(DPAD_UP,"XCrafts/ERJ/VNAV")
			end
					
			-- Flash Light
			if sp5_pressed and not MULTI_SIXPACK_PRESSED then
				command_once("sim/view/flashlight_red")
				MULTI_SIXPACK_PRESSED = true
			else
				STILL_PRESSED = true
			end
		
		end

		if sp3_pressed then

			if not STILL_PRESSED then
				set_button_assignment(RIGHT_BUMPER,"XCrafts/ERJ/alt_hold")
				set_button_assignment(SIXPACK_6,"XCrafts/Lights/all_landing_lights_toggle")
				--set_button_assignment(LEFT_BUMPER,"1-sim/command/mcpAltHoldButton_button")
				STILL_PRESSED = true
			end

			if dpad_up_pressed then

				meterE175Interaction("XCrafts/ERJ/ALT_up_100", "XCrafts/ERJ/ALT_up_1000", 2.0) -- after around 2 seconds, increment more quickly
				
				DPAD_PRESSED = true
			
			elseif dpad_down_pressed then
					
				meterE175Interaction("XCrafts/ERJ/ALT_dn_100", "XCrafts/ERJ/ALT_dn_1000", 2.0)
				
				DPAD_PRESSED = true
			
			end
			
		end
		
		if sp5_pressed then
			if not STILL_PRESSED then
				-- built-in XP12 commands are used in the E-175 for heading. More A/C should use built-in commands!
				set_button_assignment(DPAD_UP,"sim/autopilot/heading_up")
				set_button_assignment(DPAD_DOWN,"sim/autopilot/heading_down")
				set_button_assignment(RIGHT_BUMPER,"sim/autopilot/heading")
			end
			STILL_PRESSED = true
		end
		
		if sp6_pressed then
			set_button_assignment(DPAD_LEFT,"sim/none/none")
			set_button_assignment(DPAD_RIGHT,"sim/none/none")
			set_button_assignment(DPAD_CENTER,"sim/none/none")
			if dpad_up_pressed then
				meterE175Interaction("XCrafts/ERJ/VS_up_10", "XCrafts/ERJ/VS_up_100", 0.5) -- VS increments more slowly, so use 0.5 seconds until larger increment starts
				DPAD_PRESSED = true
			elseif dpad_down_pressed then
				meterE175Interaction("XCrafts/ERJ/VS_dn_10", "XCrafts/ERJ/VS_dn_100", 0.5)
				DPAD_PRESSED = true
			elseif dpad_left_pressed then
				meterE175Interaction("XCrafts/ERJ/FPA_dn_pt_one","XCrafts/ERJ/FPA_dn_one",0.5)
				DPAD_PRESSED = true
			elseif dpad_right_pressed then
				meterE175Interaction("XCrafts/ERJ/FPA_up_pt_one","XCrafts/ERJ/FPA_up_one",0.5)
				DPAD_PRESSED = true
			end
			
			if not STILL_PRESSED then
				set_button_assignment(RIGHT_BUMPER,"XCrafts/ERJ/VS")
				set_button_assignment(DPAD_CENTER,"XCrafts/ERJ/FPA")
				STILL_PRESSED = true
			else
				STILL_PRESSED = true
			end

		end

-- parking brake			
		if left_bumper_pressed then
			set_button_assignment(SIXPACK_2,"sim/none/none")
			set_button_assignment(SIXPACK_1,"sim/none/none")
			--set_button_assignment(RIGHT_BUMPER,"XCrafts/ERJ/VNAV")
			if not STILL_PRESSED then
				set_button_assignment(WHEEL_UP,"sim/flight_controls/brakes_toggle_max")
				set_button_assignment(WHEEL_DOWN,"sim/flight_controls/brakes_toggle_max")
			end
				-- Cockpit camera height not implemented as it deals with the rudder axes.....
			if sp1_pressed and not MULTI_SIXPACK_PRESSED then
				if dpad_up_pressed then
					-- EFB but this doesn't quite work. E175.
					set_pilots_head(-0.60079902410507,1.5304770469666,-11.694169998169,306.1875,-17.333335876465)
				else
					-- Glareshield E175
					set_pilots_head(0.02934099920094,1.5158799886703,-11.56796169281,359.8125,-18.925168991089)
				end
				MULTI_SIXPACK_PRESSED = true
			elseif sp2_pressed and not MULTI_SIXPACK_PRESSED then
				-- Nav, CDU, Transponder, etc E175
				set_pilots_head(0.024648999795318,1.51879799366,-11.603151321411,359.4375,-70.895484924316)
				MULTI_SIXPACK_PRESSED = true
			elseif sp3_pressed and not MULTI_SIXPACK_PRESSED then
				-- FMS E175
				set_pilots_head(-0.122503452003,1.3184984922409,-11.969388961792,0.29323375225067,-55.484268188477)
				MULTI_SIXPACK_PRESSED = true
			elseif sp4_pressed and not MULTI_SIXPACK_PRESSED then
				-- Overhead panel E175
				set_pilots_head(0.0043500000610948,1.2554479837418,-11.344659805298,359.4375,62.333358764648)
				MULTI_SIXPACK_PRESSED = true
			elseif sp5_pressed and not MULTI_SIXPACK_PRESSED then
				-- Pilot's view of throttles, flaps, speed brake, pitch trim, fuel cutoffs E175
				set_pilots_head(-0.51060301065445,1.575464963913,-11.575117111206,32.25,-40.661045074463)
				MULTI_SIXPACK_PRESSED = true
			elseif sp6_pressed and not MULTI_SIXPACK_PRESSED then
				-- E175 Cabin lighting panel
				set_pilots_head(-0.40489101409912,1.8724830150604,-9.5096197128296,357.5625,3.160783290863)
				MULTI_SIXPACK_PRESSED = true
			end
			
			STILL_PRESSED = true
		end
				

-- DPAD_up mode
		if dpad_up_pressed then
			if not STILL_PRESSED then
				set_button_assignment(RIGHT_BUMPER,"XCrafts/ERJ/TOGA") -- there's only a toggle (Will investigate later)
				set_button_assignment(WHEEL_UP,"sim/flight_controls/flaps_down")
				set_button_assignment(WHEEL_DOWN,"sim/flight_controls/flaps_up")
				set_button_assignment(POV_LEFT,"sim/view/glance_left")
				set_button_assignment(POV_RIGHT,"sim/view/glance_right")
				set_button_assignment(POV_UP,"sim/view/straight_up")
				set_button_assignment(POV_DOWN,"sim/view/straight_down")
		
				set_button_assignment(DPAD_LEFT,"sim/none/none")
				set_button_assignment(DPAD_RIGHT,"sim/none/none")
			end
			
			if dpad_left_pressed then
				-- Pilot's seat E175
				--headX, headY, headZ, heading, pitch = get_pilots_head()
				--print(headX .. "," .. headY .. "," .. headZ .. "," .. heading .. "," .. pitch)
				set_pilots_head(-0.510603,1.575465,-11.575117,0.375000,-11.666667)

			elseif dpad_right_pressed then
				-- Copilot's seat E175
				set_pilots_head(0.561862,1.575465,-11.575117,0.375000,-11.666667)

			end
			STILL_PRESSED = true

		end
		
-- DPAD_down mode
		if dpad_down_pressed then
			if not STILL_PRESSED then
				set_button_assignment(RIGHT_BUMPER,"XCrafts/ERJ/takeoff")
			end
			
			STILL_PRESSED = true
		end

-- All buttons need to be released to end STILL_PRESSED phase
		if not sp1_pressed and not sp2_pressed and not sp3_pressed and not sp4_pressed and not sp5_pressed and not sp6_pressed and not right_bumper_pressed and not left_bumper_pressed and not dpad_center_pressed and not dpad_down_pressed then
			STILL_PRESSED = false
		end

		if not sp1_pressed and not sp2_pressed and not sp3_pressed and not sp4_pressed and not sp5_pressed and not sp6_pressed then
			MULTI_SIXPACK_PRESSED = false
		end 
		
		if not dpad_up_pressed and not dpad_left_pressed and not dpad_right_pressed and not dpad_down_pressed then
			DPAD_PRESSED = false
		end

    end 
end

-- Don't mess with other configurations
if PLANE_ICAO == "E175" then 
	clear_all_button_assignments()

--[[
set_axis_assignment(STICK_X, "roll", "normal" )
set_axis_assignment(STICK_Y, "pitch", "normal" )
set_axis_assignment(POLE_RIGHT, "reverse", "reverse")
set_axis_assignment(POLE_RIGHT, "speedbrakes", "reverse")
set_axis_assignment(RUDDER, "yaw", "normal" )
]]

	do_every_frame("multipressXCraftsE175_buttons()")
end
