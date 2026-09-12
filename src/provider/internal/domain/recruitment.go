package domain

import "time"

const (
	RecruitmentActionCreateReport          = "create_report"
	RecruitmentActionSyncInbox             = "sync_inbox"
	RecruitmentActionUpdateCandidateStatus = "update_candidate_status"
	RecruitmentActionSendSurvey            = "send_survey"
	RecruitmentActionSendTrainingInvite    = "send_training_invite"
	RecruitmentActionSendExam              = "send_exam"
	RecruitmentActionCreateInterviewNotice = "create_interview_notice"
	RecruitmentActionStatusDraft           = "draft"
	RecruitmentActionStatusSent            = "sent"
	RecruitmentActionStatusFailed          = "failed"
	RecruitmentActionStatusDryRun          = "dry_run"
	RecruitmentActionStatusViewed          = "viewed"
	RecruitmentActionStatusDownloaded      = "downloaded"
	RecruitmentReportStatusCreated         = "created"
	RecruitmentReportStatusDryRun          = "dry_run"
	RecruitmentReportStatusFailed          = "failed"
	RecruitmentInboxStatusSynced           = "synced"
	RecruitmentInboxStatusDryRun           = "dry_run"
	RecruitmentInboxStatusFailed           = "failed"
)

// 候选人人工审核状态。空串表示来源未给出结论，按「尚未决定」处理。
const (
	RecruitmentCandidateStatusPending  = "pending"
	RecruitmentCandidateStatusPassed   = "passed"
	RecruitmentCandidateStatusRejected = "rejected"
)

// RecruitmentFlowActions 是可以对候选人外发的流程动作。
var RecruitmentFlowActions = []string{
	RecruitmentActionSendSurvey,
	RecruitmentActionSendTrainingInvite,
	RecruitmentActionSendExam,
	RecruitmentActionCreateInterviewNotice,
}

// AllowedRecruitmentActions 返回候选人当前状态下允许执行的流程动作。
//
// 这是动作准入规则的唯一定义处：provider 在真正执行前用它做闸门，
// 界面也应当只渲染这里返回的动作，两边不再各写一份判断。
//
// 规则：只有「已通过」的候选人可以外发。待处理尚未做出决定，已拒绝属于终态，
// 状态缺失（空串）同样视为未决定——三者都不允许发送。
//
// 如果业务上确实允许「未经审核直接发送」，只需把下面的判断改成
// `candidate.Status == RecruitmentCandidateStatusRejected` 取反。
func AllowedRecruitmentActions(candidate RecruitmentCandidate) []string {
	if candidate.Status != RecruitmentCandidateStatusPassed {
		return nil
	}
	return append([]string(nil), RecruitmentFlowActions...)
}

// CanRunRecruitmentAction 判断某个流程动作在当前状态下是否允许执行。
func CanRunRecruitmentAction(candidate RecruitmentCandidate, action string) bool {
	for _, allowed := range AllowedRecruitmentActions(candidate) {
		if allowed == action {
			return true
		}
	}
	return false
}

// RecruitmentActionBlockedReason 返回动作被拒绝的可读原因，便于直接回给界面。
func RecruitmentActionBlockedReason(candidate RecruitmentCandidate) string {
	switch candidate.Status {
	case RecruitmentCandidateStatusRejected:
		return "该候选人已拒绝，不再提供外发动作。"
	case RecruitmentCandidateStatusPassed:
		return "该动作不属于可执行的流程动作。"
	default:
		return "该候选人尚未通过人工审核，暂不能外发流程动作。"
	}
}

type RecruitmentCandidate struct {
	ID                string                        `json:"id"`
	Name              string                        `json:"name"`
	Email             string                        `json:"email"`
	Subject           string                        `json:"subject,omitempty"`
	Body              string                        `json:"body,omitempty"`
	Position          string                        `json:"position,omitempty"`
	Stage             string                        `json:"stage"`
	Status            string                        `json:"status"`
	HasResume         bool                          `json:"has_resume"`
	HasCoverLetter    bool                          `json:"has_cover_letter"`
	ResumeAttachments []RecruitmentResumeAttachment `json:"resume_attachments,omitempty"`
	SourceMessageID   string                        `json:"source_message_id,omitempty"`
	LastAction        string                        `json:"last_action,omitempty"`
	ReceivedAt        time.Time                     `json:"received_at,omitempty"`
	UpdatedAt         time.Time                     `json:"updated_at"`
}

type RecruitmentResumeAttachment struct {
	FileName    string `json:"file_name"`
	ContentType string `json:"content_type,omitempty"`
	URL         string `json:"url,omitempty"`
	SizeBytes   int64  `json:"size_bytes,omitempty"`
	SourceID    string `json:"-"`
}

type RecruitmentResumeViewResult struct {
	URL       string    `json:"url"`
	ExpiresAt time.Time `json:"expires_at"`
}

type RecruitmentProviderStatus struct {
	Status     string                               `json:"status"`
	Ready      bool                                 `json:"ready"`
	Operator   string                               `json:"operator,omitempty"`
	Mailbox    string                               `json:"mailbox"`
	Message    string                               `json:"message"`
	Components []RecruitmentProviderStatusComponent `json:"components"`
	CheckedAt  time.Time                            `json:"checked_at"`
}

type RecruitmentProviderStatusComponent struct {
	Name    string `json:"name"`
	Status  string `json:"status"`
	Message string `json:"message"`
	Version string `json:"version,omitempty"`
}

type RecruitmentReportRequest struct {
	Days   *int    `json:"days,omitempty"`
	Start  *string `json:"start,omitempty"`
	End    *string `json:"end,omitempty"`
	DryRun *bool   `json:"dry_run,omitempty"`
}

func (r RecruitmentReportRequest) IsDryRun(defaultValue bool) bool {
	if r.DryRun == nil {
		return defaultValue
	}
	return *r.DryRun
}

type RecruitmentReportResult struct {
	ReportID  string         `json:"report_id"`
	Status    string         `json:"status"`
	Markdown  string         `json:"markdown"`
	Metrics   map[string]int `json:"metrics,omitempty"`
	CreatedAt time.Time      `json:"created_at"`
}

type RecruitmentInboxSyncRequest struct {
	Mailbox  string `json:"mailbox,omitempty"`
	Folder   string `json:"folder,omitempty"`
	PageSize *int   `json:"page_size,omitempty"`
	DryRun   *bool  `json:"dry_run,omitempty"`
}

func (r RecruitmentInboxSyncRequest) IsDryRun(defaultValue bool) bool {
	if r.DryRun == nil {
		return defaultValue
	}
	return *r.DryRun
}

type RecruitmentInboxSyncResult struct {
	SyncID     string                 `json:"sync_id"`
	Status     string                 `json:"status"`
	Mailbox    string                 `json:"mailbox"`
	Folder     string                 `json:"folder"`
	Scanned    int                    `json:"scanned"`
	Imported   int                    `json:"imported"`
	Candidates []RecruitmentCandidate `json:"candidates"`
	CreatedAt  time.Time              `json:"created_at"`
}

type RecruitmentCandidateStatusUpdateRequest struct {
	Status string `json:"status"`
}

type RecruitmentActionRequest struct {
	Action string         `json:"action"`
	DryRun *bool          `json:"dry_run,omitempty"`
	Params map[string]any `json:"params"`
}

func (r RecruitmentActionRequest) IsDryRun(defaultValue bool) bool {
	if r.DryRun == nil {
		return defaultValue
	}
	return *r.DryRun
}

type RecruitmentActionResult struct {
	ActionID          string    `json:"action_id"`
	CandidateID       string    `json:"candidate_id"`
	Action            string    `json:"action"`
	Status            string    `json:"status"`
	Message           string    `json:"message"`
	ExternalMessageID string    `json:"external_message_id,omitempty"`
	CreatedAt         time.Time `json:"created_at"`
}

type RecruitmentAdapterReportResult struct {
	Markdown string
	Metrics  map[string]int
}

type RecruitmentAdapterActionResult struct {
	Status            string
	Message           string
	ExternalMessageID string
}

type RecruitmentAdapterInboxSyncResult struct {
	Status     string
	Mailbox    string
	Folder     string
	Scanned    int
	Imported   int
	Candidates []RecruitmentCandidate
}

type RecruitmentAdapterResumeResult struct {
	Path        string
	FileName    string
	ContentType string
	SizeBytes   int64
}

type RecruitmentAdapterActionCall struct {
	Candidate RecruitmentCandidate
	Request   RecruitmentActionRequest
}

type RecruitmentAuditEntry struct {
	ActionID          string    `json:"action_id"`
	CandidateID       string    `json:"candidate_id,omitempty"`
	Action            string    `json:"action"`
	Operator          string    `json:"operator"`
	Status            string    `json:"status"`
	Message           string    `json:"message"`
	ExternalMessageID string    `json:"external_message_id,omitempty"`
	CreatedAt         time.Time `json:"created_at"`
}
