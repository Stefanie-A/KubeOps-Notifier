import { Component } from "react";
import {
  addTask,
  getTasks,
  updateTask,
  deleteTask,
} from "./services/taskServices";

class Tasks extends Component {
  state = { tasks: [], currentTask: "" };

  async componentDidMount() {
    try {
      const { data } = await getTasks();
      this.setState({ tasks: data });
    } catch (error) {
      console.log(error);
    }
  }

  handleChange = ({ currentTarget: input }) => {
    this.setState({ currentTask: input.value });
  };

  handleSubmit = async (e) => {
  e.preventDefault();
  const originalTasks = this.state.tasks;
  try {
    const { data } = await addTask({ task: this.state.currentTask }); // 👈 send { task }
    const tasks = [...originalTasks, data];
    this.setState({ tasks, currentTask: "" });
  } catch (error) {
    console.log(error);
  }
};
  handleUpdate = async (id) => {
    const originalTasks = this.state.tasks;
    try {
      const tasks = [...originalTasks];
      const index = tasks.findIndex((task) => task._id === id);
      tasks[index] = { ...tasks[index], completed: !tasks[index].completed };
      this.setState({ tasks });
      await updateTask(id, { completed: tasks[index].completed });
    } catch (error) {
      this.setState({ tasks: originalTasks });
      console.log(error);
    }
  };

  handleDelete = async (id) => {
    const originalTasks = this.state.tasks;
    try {
      const tasks = originalTasks.filter((task) => task._id !== id);
      this.setState({ tasks });
      await deleteTask(id);
    } catch (error) {
      this.setState({ tasks: originalTasks });
      console.log(error);
    }
  };

  render() {
    return (
      <div>
        <h2>My Tasks</h2>
        <form onSubmit={this.handleSubmit}>
          <input
            type="text"
            value={this.state.currentTask}
            onChange={this.handleChange}  // 👈 now used
            placeholder="Add a task"
          />
          <button type="submit">Add</button>
        </form>

        <ul>
          {this.state.tasks.map((task) => (
            <li key={task._id}>
  <span
    style={{
      textDecoration: task.completed ? "line-through" : "none",
      cursor: "pointer",
    }}
    onClick={() => this.handleUpdate(task._id)}
  >
    {task.task}   {/* 👈 change from task.title to task.task */}
  </span>
  <button onClick={() => this.handleDelete(task._id)}>❌</button>
</li>

          ))}
        </ul>
      </div>
    );
  }
}

export default Tasks;
