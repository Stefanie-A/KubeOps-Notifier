const express = require("express");
const mongoose = require("mongoose");
const Task = require("../models/task"); // make sure this path is correct  
const router = express.Router();

// Get all tasks
router.get("/", async (req, res) => {
  try {
    const tasks = await Task.find();
    res.json(tasks);
  } catch (error) {
    res.status(500).json({ error: "Server error" });
  }
});

// Create a new task
router.post("/", async (req, res) => {
  try {
      const newTask = new Task({
      task: req.body.task,
      completed: req.body.completed || false
    });
    await newTask.save();
    res.status(201).json(newTask);
  } catch (error) {
    console.error("Create error:", error.message);
    res.status(400).json({ error: error.message });
  }
});

// Update a task
router.put("/:id", async (req, res) => {
  try {
    if (!mongoose.isValidObjectId(req.params.id)) {
      return res.status(400).json({ error: "Invalid task ID" });
    }

    const { title, description, status } = req.body;
    const updateData = {};
    if (title !== undefined) updateData.title = title;
    if (description !== undefined) updateData.description = description;
    if (status !== undefined) updateData.status = status;

    if (Object.keys(updateData).length === 0) {
      return res.status(400).json({ error: "No valid fields provided for update" });
    }

    const task = await Task.findByIdAndUpdate(
      req.params.id,
      updateData,
      { new: true, runValidators: true }
    );

    if (!task) {
      return res.status(404).json({ error: "Task not found" });
    }

    res.json(task);
  } catch (error) {
    console.error("Update error:", error.message);
    res.status(400).json({ error: error.message });
  }
});

router.delete("/:id", async (req, res) => {
  try {
    if (!mongoose.isValidObjectId(req.params.id)) {
      return res.status(400).json({ error: "Invalid task ID" });
    }

    const task = await Task.findByIdAndDelete(req.params.id);
    if (!task) {
      return res.status(404).json({ error: "Task not found" });
    }

    res.json({ message: "Task deleted" });
  } catch (error) {
    console.error("Delete error:", error.message);
    res.status(500).json({ error: "Server error" });
  }
});

module.exports = router;
