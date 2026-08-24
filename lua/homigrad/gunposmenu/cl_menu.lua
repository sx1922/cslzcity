

local red = Color(75,25,25)
local redselected = Color(150,0,0)

local blurMat = Material("pp/blurscreen")
local Dynamic = 0

BlurBackground = BlurBackground or hg.DrawBlur

local function CreateOptionsMenu()
    local sizeX,sizeY = ScrW() / 3.2 ,ScrH() / 2.2
	local posX,posY = ScrW() / 2 - sizeX / 2,ScrH() / 2 - sizeY / 2

    local MainFrame = vgui.Create("ZFrame") -- The name of the panel we don't have to parent it.
    MainFrame:SetPos( posX, posY ) -- Set the position to 100x by 100y. 
    MainFrame:SetSize( sizeX, sizeY ) -- Set the size to 300x by 200y.
    MainFrame:SetTitle( "武器选项" ) -- Set the title in the top left to "Derma Frame".
    MainFrame:MakePopup() -- Makes your mouse be able to move around.
    function MainFrame:Paint( w, h )
        draw.RoundedBox( 0, 2.5, 2.5, w-5, h-5, Color( 0, 0, 0, 140) )
        BlurBackground(MainFrame)
        surface.SetDrawColor( 255, 0, 0, 128)
        surface.DrawOutlinedRect( 0, 0, w, h, 2.5 )
    end

    local DScrollPanel = vgui.Create("DScrollPanel", MainFrame)
	DScrollPanel:SetPos(10, 50)
	DScrollPanel:SetSize(sizeX - 20, sizeY - 60)
	function DScrollPanel:Paint( w, h )
		BlurBackground(self)

		surface.SetDrawColor( 255, 0, 0, 128)
        surface.DrawOutlinedRect( 0, 0, w, h, 2.5 )
	end

    local DLabel = vgui.Create( "DLabel", DScrollPanel )
    DLabel:Dock(TOP)
    DLabel:DockMargin(20,5,5,2.5)
    DLabel:SetText( "位置" )

    local DermaNumSlider = vgui.Create( "DNumSlider", DScrollPanel )
    DermaNumSlider:Dock( TOP )
    DermaNumSlider:DockMargin(10,5,5,2.5)	
    DermaNumSlider:SetSize(50,45)	
    DermaNumSlider:SetText( "原点 X" )	
    DermaNumSlider:SetMin( -4 )				 	
    DermaNumSlider:SetMax( 4 )				
    DermaNumSlider:SetDecimals( 2 )				
    DermaNumSlider:SetConVar( "hg_gunorigin_x" )	
    DermaNumSlider:SizeToContents()

    local DermaNumSlider = vgui.Create( "DNumSlider", DScrollPanel )
    DermaNumSlider:Dock( TOP )
    DermaNumSlider:DockMargin(10,5,5,2.5)	
    DermaNumSlider:SetSize(50,45)	
    DermaNumSlider:SetText( "原点 Y" )	
    DermaNumSlider:SetMin( -4 )				 	
    DermaNumSlider:SetMax( 4 )				
    DermaNumSlider:SetDecimals( 2 )				
    DermaNumSlider:SetConVar( "hg_gunorigin_y" )	
    DermaNumSlider:SizeToContents()

    local DermaNumSlider = vgui.Create( "DNumSlider", DScrollPanel )
    DermaNumSlider:Dock( TOP )
    DermaNumSlider:DockMargin(10,5,5,2.5)	
    DermaNumSlider:SetSize(50,45)	
    DermaNumSlider:SetText( "原点 Z" )	
    DermaNumSlider:SetMin( -4 )				 	
    DermaNumSlider:SetMax( 4 )				
    DermaNumSlider:SetDecimals( 2 )				
    DermaNumSlider:SetConVar( "hg_gunorigin_z" )	
    DermaNumSlider:SizeToContents()
--[[
    local DLabel = vgui.Create( "DLabel", DScrollPanel )
    DLabel:Dock(TOP)
    DLabel:DockMargin(20,5,5,2.5)
    DLabel:SetText( "角度" )

    local DermaNumSlider = vgui.Create( "DNumSlider", DScrollPanel )
    DermaNumSlider:Dock( TOP )
    DermaNumSlider:DockMargin(10,5,5,2.5)
    DermaNumSlider:SetSize(50,45)
    DermaNumSlider:SetText( "俯仰角" )
    DermaNumSlider:SetMin( -20 ) 	
    DermaNumSlider:SetMax( 20 )
    DermaNumSlider:SetDecimals( 2 )
    DermaNumSlider:SetConVar( "hg_gunangle_p" )
    DermaNumSlider:SizeToContents()
    
    local DermaNumSlider = vgui.Create( "DNumSlider", DScrollPanel )
    DermaNumSlider:Dock( TOP )
    DermaNumSlider:DockMargin(10,5,5,2.5)	
    DermaNumSlider:SetSize(50,45)	
    DermaNumSlider:SetText( "偏航角" )	
    DermaNumSlider:SetMin( -20 )				 	
    DermaNumSlider:SetMax( 20 )				
    DermaNumSlider:SetDecimals( 2 )				
    DermaNumSlider:SetConVar( "hg_gunangle_y" )	
    DermaNumSlider:SizeToContents()

    local DermaNumSlider = vgui.Create( "DNumSlider", DScrollPanel )
    DermaNumSlider:Dock( TOP )
    DermaNumSlider:DockMargin(10,5,5,2.5)	
    DermaNumSlider:SetSize(50,45)	
    DermaNumSlider:SetText( "翻滚角" )	
    DermaNumSlider:SetMin( -20 )				 	
    DermaNumSlider:SetMax( 20 )				
    DermaNumSlider:SetDecimals( 2 )				
    DermaNumSlider:SetConVar( "hg_gunangle_r" )	
    DermaNumSlider:SizeToContents()--]]
end

concommand.Add("hg_weaponsettings",function()
    CreateOptionsMenu()
end)