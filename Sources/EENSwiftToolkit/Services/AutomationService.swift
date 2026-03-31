import Foundation

/// Service for Automation API endpoints (rules and actions).
public struct AutomationService: Sendable {
    let client: HTTPClient

    // MARK: - Event Alert Condition Rules

    /// List event alert condition rules.
    public func listEventAlertConditionRules(params: ListEventAlertConditionRulesParams = .init()) async throws -> PaginatedResult<EventAlertConditionRule> {
        try await client.request(Endpoint(path: "/api/v3.0/eventAlertConditionRules", queryItems: params.toQueryItems()))
    }

    /// Get event alert condition rule field values.
    public func getEventAlertConditionRuleFieldValues(enabled: Bool? = nil) async throws -> EventAlertConditionRuleFieldValues {
        var queryItems: [URLQueryItem] = []
        if let enabled { queryItems.append(URLQueryItem(name: "enabled", value: String(enabled))) }
        return try await client.request(Endpoint(path: "/api/v3.0/eventAlertConditionRules:fieldValues", queryItems: queryItems))
    }

    /// Get a single event alert condition rule by ID.
    public func getEventAlertConditionRule(id: String) async throws -> EventAlertConditionRule {
        try await client.request(Endpoint(path: "/api/v3.0/eventAlertConditionRules/\(id)"))
    }

    // MARK: - Alert Condition Rules

    /// List alert condition rules.
    public func listAlertConditionRules(params: ListAlertConditionRulesParams = .init()) async throws -> PaginatedResult<AlertConditionRule> {
        try await client.request(Endpoint(path: "/api/v3.0/alertConditionRules", queryItems: params.toQueryItems()))
    }

    /// Get a single alert condition rule by ID.
    public func getAlertConditionRule(id: String, include: [String]? = nil) async throws -> AlertConditionRule {
        var queryItems: [URLQueryItem] = []
        if let include, !include.isEmpty {
            queryItems.append(URLQueryItem(name: "include", value: include.joined(separator: ",")))
        }
        return try await client.request(Endpoint(path: "/api/v3.0/alertConditionRules/\(id)", queryItems: queryItems))
    }

    // MARK: - Alert Action Rules

    /// List alert action rules.
    public func listAlertActionRules(params: ListAlertActionRulesParams = .init()) async throws -> PaginatedResult<AlertActionRule> {
        try await client.request(Endpoint(path: "/api/v3.0/alertActionRules", queryItems: params.toQueryItems()))
    }

    /// Get a single alert action rule by ID.
    public func getAlertActionRule(id: String) async throws -> AlertActionRule {
        try await client.request(Endpoint(path: "/api/v3.0/alertActionRules/\(id)"))
    }

    // MARK: - Alert Actions

    /// List alert actions.
    public func listAlertActions(params: ListAlertActionsParams = .init()) async throws -> PaginatedResult<AutomationAlertAction> {
        try await client.request(Endpoint(path: "/api/v3.0/alertActions", queryItems: params.toQueryItems()))
    }

    /// Get a single alert action by ID.
    public func getAlertAction(id: String) async throws -> AutomationAlertAction {
        try await client.request(Endpoint(path: "/api/v3.0/alertActions/\(id)"))
    }
}
