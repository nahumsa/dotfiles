return {
  "theprimeagen/harpoon",
  branch = "harpoon2",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    require("harpoon"):setup()
  end,
  keys = {
    {
      "<leader>A",
      function()
        require("harpoon"):list():add()
      end,
      desc = "harpoon file",
    },
    {
      "<leader>a",
      function()
        local harpoon = require("harpoon")

        local conf = require("telescope.config").values
        local function toggle_telescope(harpoon_files)
          local file_paths = {}
          for _, item in ipairs(harpoon_files.items) do
            table.insert(file_paths, item.value)
          end

          require("telescope.pickers")
            .new({}, {
              prompt_title = "Harpoon",
              finder = require("telescope.finders").new_table({
                results = file_paths,
              }),
              previewer = conf.file_previewer({}),
              sorter = conf.generic_sorter({}),
            })
            :find()
        end
        toggle_telescope(harpoon:list())
      end,
      desc = "harpoon quick menu",
    },
    {
      "<leader>1",
      function()
        require("harpoon"):list():select(1)
      end,
      desc = "harpoon to file 1",
    },
    {
      "<leader>2",
      function()
        require("harpoon"):list():select(2)
      end,
      desc = "harpoon to file 2",
    },
    {
      "<leader>3",
      function()
        require("harpoon"):list():select(3)
      end,
      desc = "harpoon to file 3",
    },
    {
      "<leader>4",
      function()
        require("harpoon"):list():select(4)
      end,
      desc = "harpoon to file 4",
    },
    {
      "<leader>5",
      function()
        require("harpoon"):list():select(5)
      end,
      desc = "harpoon to file 5",
    },
    {
      "<leader>hr1",
      function()
        require("harpoon"):list():replace_at(1)
      end,
      desc = "replace harpoon on file 1",
    },
    {
      "<leader>hr2",
      function()
        require("harpoon"):list():replace_at(2)
      end,
      desc = "replace harpoon on file 2",
    },
    {
      "<leader>hr3",
      function()
        require("harpoon"):list():replace_at(3)
      end,
      desc = "replace harpoon on file 3",
    },
    {
      "<leader>hr4",
      function()
        require("harpoon"):list():replace_at(4)
      end,
      desc = "replace harpoon on file 4",
    },
    {
      "<leader>hr5",
      function()
        require("harpoon"):list():replace_at(5)
      end,
      desc = "replace harpoon on file 5",
    },
    {
      "<leader>hc",
      function()
        require("harpoon"):list():clear()
      end,
      desc = "clear harpoon list",
    },
  },
}
