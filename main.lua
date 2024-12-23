local json = require("cjson")

local board_width = 10
local board_height = 20
local block_size = 30
local board = {}
local game_over = false

local tetrominoes = {
    { {1, 1, 1, 1} },
    { {1, 1}, {1, 1} },
    { {1, 1, 0}, {0, 1, 1} },
    { {0, 1, 1}, {1, 1, 0} },
    { {1,1,1}, {1,0,0}},
}

local current_tetromino
local current_x, current_y
local fall_speed = 0.5
local fall_timer = 0

local in_menu = true
local selected_option = 1

local place_sound
local clear_sound

function love.load()
    place_sound = love.audio.newSource("sounds/place_sound.mp3", "static")
    clear_sound = love.audio.newSource("sounds/clear_sound.mp3", "static")
end

function draw_menu()
    love.graphics.setColor(0.949, 0.882, 0.929)

    love.graphics.rectangle("fill", 50, 50, 200, 300)
    love.graphics.setColor(0.251, 0.22, 0.239)

    love.graphics.print("Tetris Game", 115, 70)
    love.graphics.print("Play", 140, 130)
    love.graphics.print("Load", 140, 160)
    love.graphics.print("Instructions:", 110, 200)
    love.graphics.print("Press 'Ctrl + s' to save.", 80, 230)
    love.graphics.print("Press 'Ctrl + c' to stop game.", 60, 260)

    if selected_option == 1 then
        love.graphics.setColor(0.929, 0.424, 0.776)
        love.graphics.rectangle("line", 125, 125, 55, 25)
    elseif selected_option == 2 then
        love.graphics.setColor(0.929, 0.424, 0.776)
        love.graphics.rectangle("line", 125, 155, 55, 25)
    end
end

function draw_board()
    for y = 1, board_height do
        for x = 1, board_width do
            if board[y] and board[y][x] then
                love.graphics.setColor(0.5, 0.5, 0.5)
                love.graphics.rectangle("fill", (x-1) * block_size, (y-1) * block_size, block_size, block_size)
            end
        end
    end
end

function draw_tetromino()
    love.graphics.setColor(0.929, 0.424, 0.776)
    for row = 1, #current_tetromino do
        for col = 1, #current_tetromino[row] do
            if current_tetromino[row][col] == 1 then
                love.graphics.rectangle(
                    "fill",
                    (current_x + col - 2) * block_size,
                    (current_y + row - 2) * block_size,
                    block_size,
                    block_size
                )
            end
        end
    end
end

function check_collision()
    for row = 1, #current_tetromino do
        for col = 1, #current_tetromino[row] do
            if current_tetromino[row][col] == 1 then
                local board_x = current_x + col - 1
                local board_y = current_y + row - 1

                if board_y > board_height or board_x < 1 or board_x > board_width or (board[board_y] and board[board_y][board_x]) then
                    return true
                end
            end
        end
    end
    return false
end

function place_tetromino()
    for row = 1, #current_tetromino do
        for col = 1, #current_tetromino[row] do
            if current_tetromino[row][col] == 1 then
                local board_x = current_x + col - 1
                local board_y = current_y + row - 1
                if board_y >= 1 then
                    board[board_y] = board[board_y] or {}
                    board[board_y][board_x] = true
                end
            end
        end
    end
    place_sound:play()
end

function clear_lines()
    local cleared = false

    for y = board_height, 1, -1 do
        if board[y] then
            local full = true
            for x = 1, board_width do
                if not board[y][x] then
                    full = false
                    break
                end
            end

            if full then
                for move_y = y, 2, -1 do
                    board[move_y] = board[move_y - 1]
                end
                board[1] = {}
                for x = 1, board_width do
                    board[1][x] = nil
                end

                cleared = true
                clear_sound:play()
                break
            end
        end
    end

    if cleared then
        clear_lines()
    end
end

function new_tetromino()
    local idx = love.math.random(1, #tetrominoes)
    current_tetromino = tetrominoes[idx]
    current_x = math.floor(board_width / 2) - math.floor(#current_tetromino[1] / 2)
    current_y = 1
    if check_collision() then
        game_over = true
    end
end

function love.update(dt)
    if game_over then
        return
    end

    if not current_tetromino then
        new_tetromino()
    end

    fall_timer = fall_timer + dt

    if fall_timer >= fall_speed then
        fall_timer = fall_timer - fall_speed
        current_y = current_y + 1

        if check_collision() then
            current_y = current_y - 1
            place_tetromino()
            clear_lines()
            new_tetromino()
        end
    end
end

function rotate_tetromino(tetromino)
    local rotated = {}
    local rows = #tetromino
    local cols = #tetromino[1]

    for x = 1, cols do
        rotated[x] = {}
        for y = 1, rows do
            rotated[x][y] = 0
        end
    end

    for y = 1, rows do
        for x = 1, cols do
            rotated[x][rows - y + 1] = tetromino[y][x]
        end
    end

    return rotated
end

function love.keypressed(key)
    if in_menu then
        if key == "down" then
            selected_option = selected_option + 1
            if selected_option > 2 then
                selected_option = 1 
            end
        elseif key == "up" then
            selected_option = selected_option - 1
            if selected_option < 1 then
                selected_option = 2
            end
        elseif key == "return" then
            if selected_option == 1 then
                in_menu = false
                new_tetromino()
            elseif selected_option == 2 then
                load_game()
                in_menu = false
            end
        end
    else
        if key == "c" and love.keyboard.isDown("lctrl") then
            love.event.quit()
        elseif key == "left" then
            current_x = current_x - 1
            if check_collision() then
                current_x = current_x + 1
            end
        elseif key == "right" then
            current_x = current_x + 1
            if check_collision() then
                current_x = current_x - 1
            end
        elseif key == "down" then
            current_y = current_y + 1
            if check_collision() then
                current_y = current_y - 1 
            end
        elseif key == "up" then
            local rotated = rotate_tetromino(current_tetromino)
            local temp = current_tetromino
            current_tetromino = rotated
            if check_collision() then
                current_tetromino = temp
            end
        elseif key == "s" and love.keyboard.isDown("lctrl") then
            save_game()
        end
    end
end

function love.mousepressed(x, y, button)
    if game_over and button == 1 then
        local button_x = board_width * block_size / 2 - 50
        local button_y = board_height * block_size / 2 + 30
        local button_width = 100
        local button_height = 40

        if x >= button_x and x <= button_x + button_width and y >= button_y and y <= button_y + button_height then
            reset_game()
        end
    end
end

function save_game()
    local game_data = {
        board = nil_to_minus1(board),
        current_tetromino = current_tetromino,
        current_x = current_x,
        current_y = current_y,
    }

    local success, json_data = pcall(function()
        return json.encode(game_data)
    end)

    if not success then
        print("Error encoding JSON!")
        return
    end

    local file = love.filesystem.newFile("saved_game.json", "w")

    if not file then
        print("Failed to open save file!")
        return
    end

    file:write(json_data)
    file:close()

    print("Game saved successfully!")
end

function nil_to_minus1(obj)
    local new_table = {}
    local max_index = 0

    for i, _ in pairs(obj) do
        if i > max_index then
            max_index = i
        end
    end
    for i = 1, max_index do
        if obj[i] == nil then
            new_table[i] = -1
        else
            new_table[i] = obj[i]
        end
    end
    return new_table
end

function reset_game()
    board = {}
    current_tetromino = nil
    current_x, current_y = nil, nil
    fall_timer = 0
    game_over = false
end

function load_game()
    local success, json_data = pcall(function()
        return love.filesystem.read("saved_game.json")
    end)

    if not success then
        print("Failed to read save file!")
        return
    end

    local success, game_data = pcall(function()
        return json.decode(json_data)
    end)

    if not success then
        print("Error decoding JSON!")
        return
    end

    board = {}
    for i, value in ipairs(game_data.board) do
        if value == -1 then
            board[i] = nil
        else
            board[i] = value
        end
    end

    current_tetromino = game_data.current_tetromino
    current_x = game_data.current_x
    current_y = game_data.current_y

    print("Game loaded successfully!")
end

function love.draw()
    if in_menu then
        draw_menu()
    else
        draw_board()
        if not game_over then
            draw_tetromino()
        else
            love.graphics.setColor(1, 0, 0)
            love.graphics.printf("Game Over", 0, board_height * block_size / 2, board_width * block_size, "center")
            local button_x = board_width * block_size / 2 - 50
            local button_y = board_height * block_size / 2 + 30
            local button_width = 100
            local button_height = 40

            love.graphics.setColor(0.2, 0.2, 0.8)
            love.graphics.rectangle("fill", button_x, button_y, button_width, button_height)

            love.graphics.setColor(1, 1, 1)
            love.graphics.printf("Retry", button_x, button_y + 10, button_width, "center")
        end
    end
end

