"""AI Agent Load Balancer implementation."""

from __future__ import annotations

import json
import time
from dataclasses import dataclass, field
from datetime import datetime
from typing import Any


@dataclass
class Task:
    """Representation of a workload assigned to agents."""

    name: str
    agents: dict[str, int]
    start_time: str
    status: str
    end_time: str | None = None


@dataclass
class AIAgentLoadBalancer:
    """Load balancer that manages agent capacity and task allocation."""

    agent_capacity: dict[str, int] = field(
        default_factory=lambda: {
            "research_agents": 12,
            "development_agents": 9,
            "content_agents": 15,
            "qa_agents": 6,
            "deployment_agents": 6,
            "sales_agents": 4,
            "success_agents": 6,
            "analytics_agents": 4,
        }
    )
    current_workload: dict[str, Any] = field(
        default_factory=lambda: {
            "active_clients": 8,
            "pending_onboarding": 17,
            "delivery_queue": 42,
            "capacity_utilization": 68,
            "auto_scaling_ready": True,
        }
    )
    agent_allocation: dict[str, int] = field(init=False)
    task_queue: list[Task] = field(default_factory=list)
    completed_tasks: list[Task] = field(default_factory=list)

    def __post_init__(self) -> None:
        self.agent_allocation = dict.fromkeys(self.agent_capacity, 0)

    def get_total_capacity(self) -> int:
        """Calculate total agent capacity."""

        return sum(self.agent_capacity.values())

    def get_available_agents(self, agent_type: str) -> int:
        """Return the available agents for ``agent_type``."""

        total = self.agent_capacity.get(agent_type, 0)
        allocated = self.agent_allocation.get(agent_type, 0)
        return max(0, total - allocated)

    def allocate_agent(self, agent_type: str, count: int = 1) -> bool:
        """Allocate ``count`` agents of ``agent_type`` if available."""

        available = self.get_available_agents(agent_type)
        if available >= count:
            self.agent_allocation[agent_type] = (
                self.agent_allocation.get(agent_type, 0) + count
            )
            return True
        print(
            f"⚠️  Insufficient {agent_type}: need {count}, available {available}"
        )
        return False

    def release_agent(self, agent_type: str, count: int = 1) -> None:
        """Release ``count`` agents back to the available pool."""

        self.agent_allocation[agent_type] = max(
            0, self.agent_allocation.get(agent_type, 0) - count
        )

    def calculate_utilization(self) -> float:
        """Return overall capacity utilization percentage."""

        total_capacity = self.get_total_capacity()
        total_allocated = sum(self.agent_allocation.values())
        if total_capacity == 0:
            return 0.0
        return total_allocated / total_capacity * 100

    def should_scale_up(self) -> bool:
        """Determine whether auto-scaling should increase capacity."""

        utilization = self.calculate_utilization()
        return utilization > 80 and bool(self.current_workload["auto_scaling_ready"])

    def should_scale_down(self) -> bool:
        """Determine whether to scale down to avoid idling agents."""

        utilization = self.calculate_utilization()
        return utilization < 30

    def auto_scale(self) -> None:
        """Perform auto-scaling adjustments based on utilization."""

        if self.should_scale_up():
            print("📈 Scaling UP: High utilization detected")
            for agent_type in self.agent_capacity:
                self.agent_capacity[agent_type] = int(
                    self.agent_capacity[agent_type] * 1.5
                )
            print("✅ Capacity increased by 50%")
        elif self.should_scale_down():
            print("📉 Scaling DOWN: Low utilization detected")
            for agent_type, capacity in self.agent_capacity.items():
                allocated = self.agent_allocation.get(agent_type, 0)
                self.agent_capacity[agent_type] = max(
                    allocated + 2, int(capacity * 0.7)
                )
            print("✅ Capacity reduced to optimal level")

    def assign_task(self, task_name: str, required_agents: dict[str, int]) -> bool:
        """Assign ``task_name`` using ``required_agents`` mapping."""

        print(f"\n🔄 Processing task: {task_name}")
        can_allocate = all(
            self.get_available_agents(agent_type) >= count
            for agent_type, count in required_agents.items()
        )
        if not can_allocate:
            print("❌ Cannot assign task: insufficient agents")
            return False

        for agent_type, count in required_agents.items():
            self.allocate_agent(agent_type, count)
        task = Task(
            name=task_name,
            agents=required_agents,
            start_time=datetime.now().isoformat(),
            status="in_progress",
        )
        self.task_queue.append(task)
        print("✅ Task assigned successfully")
        return True

    def complete_task(self, task_name: str) -> None:
        """Mark a task as complete and release its agents."""

        for task in list(self.task_queue):
            if task.name == task_name:
                for agent_type, count in task.agents.items():
                    self.release_agent(agent_type, count)
                task.status = "completed"
                task.end_time = datetime.now().isoformat()
                self.completed_tasks.append(task)
                self.task_queue.remove(task)
                print(f"✅ Task '{task_name}' completed")
                break

    def get_status_report(self) -> str:
        """Generate a formatted status report for current allocation."""

        utilization = self.calculate_utilization()
        lines = [
            "╔════════════════════════════════════════════════════════════════╗",
            "║           AI AGENT LOAD BALANCER - STATUS REPORT               ║",
            "╚════════════════════════════════════════════════════════════════╝",
            "",
            "📊 SYSTEM OVERVIEW",
            "─────────────────────────────────────────────────────────────────",
            f"Timestamp: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
            f"Total Capacity: {self.get_total_capacity()} agents",
            f"Utilization: {utilization:.1f}%",
            "Auto-scaling: "
            + ("ENABLED" if self.current_workload["auto_scaling_ready"] else "DISABLED"),
            "",
            "📈 WORKLOAD METRICS",
            "─────────────────────────────────────────────────────────────────",
            f"Active Clients: {self.current_workload['active_clients']}",
            f"Pending Onboarding: {self.current_workload['pending_onboarding']}",
            f"Delivery Queue: {self.current_workload['delivery_queue']}",
            f"Active Tasks: {len(self.task_queue)}",
            f"Completed Tasks: {len(self.completed_tasks)}",
            "",
            "🤖 AGENT CAPACITY & ALLOCATION",
            "─────────────────────────────────────────────────────────────────",
        ]

        for agent_type, capacity in self.agent_capacity.items():
            allocated = self.agent_allocation.get(agent_type, 0)
            available = capacity - allocated
            usage_pct = (allocated / capacity * 100) if capacity else 0.0
            bar_length = 20
            filled = int(bar_length * usage_pct / 100)
            bar = "█" * filled + "░" * (bar_length - filled)
            lines.append(f"  {agent_type:.<25} [{bar}] {usage_pct:>5.1f}%")
            lines.append(
                f"  {'':.<25} {allocated}/{capacity} allocated, {available} available"
            )
            lines.append("")

        lines.append(
            "  ╚════════════════════════════════════════════════════════════════╝"
        )
        return "\n".join(lines)

    def export_metrics(self, filename: str = "agent_metrics.json") -> None:
        """Export current metrics to ``filename`` in JSON format."""

        metrics = {
            "timestamp": datetime.now().isoformat(),
            "capacity": self.agent_capacity,
            "allocation": self.agent_allocation,
            "workload": self.current_workload,
            "utilization": self.calculate_utilization(),
            "active_tasks": len(self.task_queue),
            "completed_tasks": len(self.completed_tasks),
            "task_history": [task.__dict__ for task in self.completed_tasks],
        }
        with open(filename, "w", encoding="utf-8") as handle:
            json.dump(metrics, handle, indent=2)
        print(f"📁 Metrics exported to {filename}")


def demo_simulation() -> None:
    """Run a demonstration of the load balancer system."""

    print("🚀 Starting AI Agent Load Balancer Demo\n")
    balancer = AIAgentLoadBalancer()

    print(balancer.get_status_report())

    tasks = [
        (
            "Client Onboarding - TechCorp",
            {"sales_agents": 1, "success_agents": 2, "development_agents": 2},
        ),
        (
            "Research Project - AI Trends",
            {"research_agents": 3, "analytics_agents": 2},
        ),
        (
            "Content Creation - Blog Series",
            {"content_agents": 4, "qa_agents": 1},
        ),
        (
            "Product Deployment - v2.5",
            {"development_agents": 3, "deployment_agents": 2, "qa_agents": 2},
        ),
    ]

    for task_name, required_agents in tasks:
        balancer.assign_task(task_name, required_agents)
        time.sleep(0.5)

    print("\n" + "=" * 70)
    print(balancer.get_status_report())

    balancer.auto_scale()

    print("\n" + "=" * 70)
    print("\n🏁 Completing tasks...\n")
    balancer.complete_task("Client Onboarding - TechCorp")
    balancer.complete_task("Research Project - AI Trends")

    print("\n" + "=" * 70)
    print(balancer.get_status_report())

    balancer.export_metrics()


if __name__ == "__main__":
    demo_simulation()
