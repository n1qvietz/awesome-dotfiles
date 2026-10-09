local spiral_floating = {
    name = "spiral floating",
}

-- First, we use a signal to recognize whether a client is being created or closed.
-- If a client is being created, newly created clients will be added to the layout.
-- If a client is being closed, the layout will be updated to remove the closed client.

return spiral_floating
