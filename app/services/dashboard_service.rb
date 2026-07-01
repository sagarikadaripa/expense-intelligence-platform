# frozen_string_literal: true

class DashboardService
  def initialize(user)
    @user = user
    @orchestrator = Agents::Orchestrator.new(user: user)
  end

  def build(period: "month")
    analytics = @orchestrator.dispatch("dashboard_report", { period: period })
    return analytics.data if analytics.failure?

    insights = @orchestrator.dispatch("generate_insights", {})
    forecast = @orchestrator.delegate("forecasting", {}, context: Agents::Context.new(user: @user))
    recommendations = @orchestrator.delegate("recommendation", {}, context: Agents::Context.new(user: @user))

    analytics.data.merge(
      narrative: analytics.data[:narrative],
      insights: insights.data[:insights] || [],
      forecast: forecast.data,
      recommendations: recommendations.data[:recommendations] || []
    )
  end
end
