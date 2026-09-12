package domain

import "testing"

func TestAllowedRecruitmentActionsOnlyForPassedCandidate(t *testing.T) {
	tests := []struct {
		name   string
		status string
		want   int
	}{
		{
			name:   "已通过可以外发",
			status: RecruitmentCandidateStatusPassed,
			want:   len(RecruitmentFlowActions),
		},
		{
			name:   "待处理不可以外发",
			status: RecruitmentCandidateStatusPending,
			want:   0,
		},
		{
			name:   "已拒绝不可以外发",
			status: RecruitmentCandidateStatusRejected,
			want:   0,
		},
		{
			name:   "状态缺失按未决定处理",
			status: "",
			want:   0,
		},
		{
			name:   "未知状态不可以外发",
			status: "weird",
			want:   0,
		},
	}

	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			candidate := RecruitmentCandidate{ID: "cand_1", Status: tc.status}
			got := AllowedRecruitmentActions(candidate)
			if len(got) != tc.want {
				t.Fatalf(
					"AllowedRecruitmentActions(status=%q) = %v, want %d 项",
					tc.status,
					got,
					tc.want,
				)
			}
		})
	}
}

func TestCanRunRecruitmentAction(t *testing.T) {
	passed := RecruitmentCandidate{ID: "cand_1", Status: RecruitmentCandidateStatusPassed}
	rejected := RecruitmentCandidate{ID: "cand_1", Status: RecruitmentCandidateStatusRejected}
	pending := RecruitmentCandidate{ID: "cand_1", Status: RecruitmentCandidateStatusPending}

	for _, action := range RecruitmentFlowActions {
		if !CanRunRecruitmentAction(passed, action) {
			t.Fatalf("已通过的候选人应允许执行 %s", action)
		}
		if CanRunRecruitmentAction(rejected, action) {
			t.Fatalf("已拒绝的候选人不应允许执行 %s", action)
		}
		if CanRunRecruitmentAction(pending, action) {
			t.Fatalf("待处理的候选人不应允许执行 %s", action)
		}
	}

	if CanRunRecruitmentAction(passed, "unknown_action") {
		t.Fatal("未知动作不应被允许")
	}
	if CanRunRecruitmentAction(passed, RecruitmentActionUpdateCandidateStatus) {
		t.Fatal("人工审核动作不属于可外发的流程动作")
	}
}

func TestAllowedRecruitmentActionsDoesNotExposeSharedSlice(t *testing.T) {
	candidate := RecruitmentCandidate{ID: "cand_1", Status: RecruitmentCandidateStatusPassed}
	got := AllowedRecruitmentActions(candidate)
	if len(got) == 0 {
		t.Fatal("expected actions for passed candidate")
	}

	got[0] = "tampered"
	if RecruitmentFlowActions[0] == "tampered" {
		t.Fatal("调用方不应能改到共享的动作清单")
	}
}

func TestRecruitmentActionBlockedReason(t *testing.T) {
	tests := []struct {
		name   string
		status string
		want   string
	}{
		{
			name:   "已拒绝",
			status: RecruitmentCandidateStatusRejected,
			want:   "该候选人已拒绝，不再提供外发动作。",
		},
		{
			name:   "待处理",
			status: RecruitmentCandidateStatusPending,
			want:   "该候选人尚未通过人工审核，暂不能外发流程动作。",
		},
		{
			name:   "状态缺失",
			status: "",
			want:   "该候选人尚未通过人工审核，暂不能外发流程动作。",
		},
	}

	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			got := RecruitmentActionBlockedReason(
				RecruitmentCandidate{ID: "cand_1", Status: tc.status},
			)
			if got != tc.want {
				t.Fatalf("RecruitmentActionBlockedReason(%q) = %q, want %q", tc.status, got, tc.want)
			}
		})
	}
}
