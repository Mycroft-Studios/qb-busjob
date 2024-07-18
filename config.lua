Config = Config or {} -- Create the Config table if it doesn't exist.

-- Set a list of allowed vehicles for the bus job.
Config.AllowedVehicles = {
    [`bus`] = Lang:t('info.bus')
}

Config.BusDepot = vector4(462.22, -641.15, 28.45, 175.0) -- Bus depot coordinates.

Config.Cooldown = 1000 -- Set the cooldown time on payments.

-- Set the bus job payment amount.
---@return integer: Returns the payment amount.
Config.CalculatePayment = function()
    local payment = math.random(15, 25) -- Generate a random payment amount.
    local randomAmount = math.random(1, 5) -- Generate a random amount.

    local r1, r2 = math.random(1, 5), math.random(1, 5) -- Generate two random numbers.

    if randomAmount == r1 or randomAmount == r2 then -- If the random amount is equal to r1 or r2.
        payment = payment + math.random(10, 20) -- Increase the payment amount.
    end

    return payment -- Return the payment amount.
end

-- Set the bus stop locations.
Config.NPCLocations = {
    vector4(304.36, -764.56, 29.31, 252.09),
    vector4(-110.31, -1686.29, 29.31, 223.84),
    vector4(-712.83, -824.56, 23.54, 194.7),
    vector4(-692.63, -670.44, 30.86, 61.84),
    vector4(-250.14, -886.78, 30.63, 8.67),
}

-- Set the NPC skins for the bus job.
Config.NpcSkins = {
    [1] = {
        `a_f_m_skidrow_01`,
        `a_f_m_soucentmc_01`,
        `a_f_m_soucent_01`,
        `a_f_m_soucent_02`,
        `a_f_m_tourist_01`,
        `a_f_m_trampbeac_01`,
        `a_f_m_tramp_01`,
        `a_f_o_genstreet_01`,
        `a_f_o_indian_01`,
        `a_f_o_ktown_01`,
        `a_f_o_salton_01`,
        `a_f_o_soucent_01`,
        `a_f_o_soucent_02`,
        `a_f_y_beach_01`,
        `a_f_y_bevhills_01`,
        `a_f_y_bevhills_02`,
        `a_f_y_bevhills_03`,
        `a_f_y_bevhills_04`,
        `a_f_y_business_01`,
        `a_f_y_business_02`,
        `a_f_y_business_03`,
        `a_f_y_business_04`,
        `a_f_y_eastsa_01`,
        `a_f_y_eastsa_02`,
        `a_f_y_eastsa_03`,
        `a_f_y_epsilon_01`,
        `a_f_y_fitness_01`,
        `a_f_y_fitness_02`,
        `a_f_y_genhot_01`,
        `a_f_y_golfer_01`,
        `a_f_y_hiker_01`,
        `a_f_y_hipster_01`,
        `a_f_y_hipster_02`,
        `a_f_y_hipster_03`,
        `a_f_y_hipster_04`,
        `a_f_y_indian_01`,
        `a_f_y_juggalo_01`,
        `a_f_y_runner_01`,
        `a_f_y_rurmeth_01`,
        `a_f_y_scdressy_01`,
        `a_f_y_skater_01`,
        `a_f_y_soucent_01`,
        `a_f_y_soucent_02`,
        `a_f_y_soucent_03`,
        `a_f_y_tennis_01`,
        `a_f_y_tourist_01`,
        `a_f_y_tourist_02`,
        `a_f_y_vinewood_01`,
        `a_f_y_vinewood_02`,
        `a_f_y_vinewood_03`,
        `a_f_y_vinewood_04`,
        `a_f_y_yoga_01`,
        `g_f_y_ballas_01`,
    },
    [2] = {
        `ig_barry`,
        `ig_bestmen`,
        `ig_beverly`,
        `ig_car3guy1`,
        `ig_car3guy2`,
        `ig_casey`,
        `ig_chef`,
        `ig_chengsr`,
        `ig_chrisformage`,
        `ig_clay`,
        `ig_claypain`,
        `ig_cletus`,
        `ig_dale`,
        `ig_dreyfuss`,
        `ig_fbisuit_01`,
        `ig_floyd`,
        `ig_groom`,
        `ig_hao`,
        `ig_hunter`,
        `csb_prolsec`,
        `ig_joeminuteman`,
        `ig_josef`,
        `ig_josh`,
        `ig_lamardavis`,
        `ig_lazlow`,
        `ig_lestercrest`,
        `ig_lifeinvad_01`,
        `ig_lifeinvad_02`,
        `ig_manuel`,
        `ig_milton`,
        `ig_mrk`,
        `ig_nervousron`,
        `ig_nigel`,
        `ig_old_man1a`,
        `ig_old_man2`,
        `ig_oneil`,
        `ig_orleans`,
        `ig_ortega`,
        `ig_paper`,
        `ig_priest`,
        `ig_prolsec_02`,
        `ig_ramp_gang`,
        `ig_ramp_hic`,
        `ig_ramp_hipster`,
        `ig_ramp_mex`,
        `ig_roccopelosi`,
        `ig_russiandrunk`,
        `ig_siemonyetarian`,
        `ig_solomon`,
        `ig_stevehains`,
        `ig_stretch`,
        `ig_talina`,
        `ig_taocheng`,
        `ig_taostranslator`,
        `ig_tenniscoach`,
        `ig_terry`,
        `ig_tomepsilon`,
        `ig_tylerdix`,
        `ig_wade`,
        `ig_zimbor`,
        `s_m_m_paramedic_01`,
        `a_m_m_afriamer_01`,
        `a_m_m_beach_01`,
        `a_m_m_beach_02`,
        `a_m_m_bevhills_01`,
        `a_m_m_bevhills_02`,
        `a_m_m_business_01`,
        `a_m_m_eastsa_01`,
        `a_m_m_eastsa_02`,
        `a_m_m_farmer_01`,
        `a_m_m_fatlatin_01`,
        `a_m_m_genfat_01`,
        `a_m_m_genfat_02`,
        `a_m_m_golfer_01`,
        `a_m_m_hasjew_01`,
        `a_m_m_hillbilly_01`,
        `a_m_m_hillbilly_02`,
        `a_m_m_indian_01`,
        `a_m_m_ktown_01`,
        `a_m_m_malibu_01`,
        `a_m_m_mexcntry_01`,
        `a_m_m_mexlabor_01`,
        `a_m_m_og_boss_01`,
        `a_m_m_paparazzi_01`,
        `a_m_m_polynesian_01`,
        `a_m_m_prolhost_01`,
        `a_m_m_rurmeth_01`,
    }
}