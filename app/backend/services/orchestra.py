from schemas.command import ActionPlan

def execute_action_plan(plan: ActionPlan):
    # TODO: 나중에 실제 모듈 연결
    return {
        "status": "planned",
        "action": plan.action,
        "params": plan.params,
        "message": f"{plan.action} 액션 계획 완료. (실행은 추후 구현)"
    }