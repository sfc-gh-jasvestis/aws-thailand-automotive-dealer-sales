'use client';

import { useEffect, useState } from 'react';
import { AppLayout } from '@/components/AppLayout';
import { KPICard } from '@/components/KPICard';
import { Chart } from '@/components/Chart';
import { DataTable } from '@/components/DataTable';
import { AskAI } from '@/components/AskAI';
import { ActionMemo } from '@/components/ActionMemo';
import { GeoMap } from '@/components/GeoMap';
import { ArchitectureDiagram } from '@/components/ArchitectureDiagram';

interface DemoNarrative {
  title: string;
  duration: string;
  thesis: string;
  tabs: any[];
}

export default function HomePage() {
  const [narrative, setNarrative] = useState<DemoNarrative | null>(null);
  const [data, setData] = useState<any>(null);

  useEffect(() => {
    fetch('/demo_narrative.json')
      .then((r) => r.json())
      .then(setNarrative)
      .catch(() => {});
    fetch('/api/data')
      .then((r) => r.json())
      .then(setData)
      .catch(() => {});
  }, []);

  const title = narrative?.title || 'SEA AWS Demo';

  const executiveCockpit = (
    <div className="space-y-6">
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <KPICard title="Dealer Revenue (MTD)" value="฿2.8B" status="neutral" />
        <KPICard title="Inventory Days" value="42" status="warning" />
        <KPICard title="Lead Conversion" value="18.7%" status="neutral" />
        <KPICard title="Active Dealers" value="312" status="neutral" />
      </div>
      <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
        <div className="lg:col-span-1">
          <GeoMap
            country="thailand"
            markers={[{"label": "Bangkok", "value": "87 dealers, \u0e3f1.2B", "color": "green", "size": "lg"}, {"label": "Chiang Mai", "value": "24 dealers", "color": "green", "size": "md"}, {"label": "Khon Kaen", "value": "18 dealers, -12%", "color": "amber", "size": "md"}, {"label": "Phuket", "value": "8 dealers", "color": "green", "size": "sm"}, {"label": "Hat Yai", "value": "12 dealers", "color": "green", "size": "sm"}]}
            routes={[]}
            title="Geographic Overview"
            height={400}
          />
        </div>
        <div className="lg:col-span-1 grid grid-cols-1 gap-4">
      <div className="grid grid-cols-1 gap-4 grid-cols-1">
        <Chart
          data={data?.timeseries || (() => { const d = []; const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec']; const base = 120; for (let i = 0; i < 12; i++) d.push({ period: months[i], value: Math.round(base + Math.sin(i/2)*40 + (Math.random()*20-10)) }); return d; })()}
          type="line"
          xKey="period"
          yKeys={[{ key: 'value', name: 'Units' }]}
          title="Sales Volume by Region (Weekly)"
        />
        <Chart
          data={data?.categories || [{ category: 'North', count: 82 }, { category: 'Central', count: 74 }, { category: 'South', count: 91 }, { category: 'Highland', count: 68 }, { category: 'Coastal', count: 77 }]}
          type="bar"
          xKey="category"
          yKeys={[{ key: 'count', name: '฿M' }]}
          title="Revenue by Model"
        />
      </div>
        </div>
      </div>
      <DataTable
        columns={[
          { key: 'id', header: 'Rank' },
          { key: 'name', header: 'Dealer' },
          { key: 'status', header: 'Trend' },
          { key: 'value', header: 'Units Sold' },
        ]}
        data={data?.entities || []}
        title="Top Dealer Performance"
      />
    </div>
  );

  const domainTab1 = (
    <div className="space-y-6">
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
        <KPICard title="EV Mix Forecast" value="34%" />
        <KPICard title="Avg Days to Sale" value="28" />
        <KPICard title="Test Drive Conversion" value="24%" />
      </div>
      <Chart
        data={data?.detail || [{ x: 'Mon', y: 24 }, { x: 'Tue', y: 28 }, { x: 'Wed', y: 22 }, { x: 'Thu', y: 31 }, { x: 'Fri', y: 26 }, { x: 'Sat', y: 19 }, { x: 'Sun', y: 23 }]}
        type="area"
        xKey="x"
        yKeys={[{ key: 'y', name: 'Units' }]}
        title="Demand Forecast by Segment"
        height={400}
      />
    </div>
  );

  const domainTab2 = (
    <div className="space-y-6">
      <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
        <Chart
          data={data?.breakdown || [{ label: 'Zone North', value: 35 }, { label: 'Zone Central', value: 28 }, { label: 'Zone South', value: 22 }, { label: 'Zone East', value: 15 }]}
          type="pie"
          xKey="label"
          yKeys={[{ key: 'value', name: 'Achievement %' }]}
          title="Performance vs Target"
        />
        <ActionMemo
          persona={{ name: 'Anuwat Prasertsri', role: 'VP Dealer Operations' }}
          context={{}}
          onGenerate={async () => {
            const memos = [
              {
                subject: 'Urgent: Operational Action Required',
                body: `Dear Leadership Team,\n\nBased on our analysis of the latest operational data, I am writing to recommend immediate action on the following critical items.\n\nKey Findings:\n- Performance metrics indicate a deviation from target KPIs in several areas\n- Predictive models suggest these trends will continue without intervention\n- Estimated impact: 12-15% improvement in efficiency if addressed within 2 weeks\n\nI recommend we schedule a review meeting this week to align on next steps.\n\nBest regards`,
                urgency: 'HIGH' as const,
                actions: 'Launch incentive for underperforming Central dealers', 'Reallocate EV inventory to Eastern region', 'Schedule dealer training for hybrid launch',
              },
              {
                subject: 'Weekly Performance Summary & Recommendations',
                body: `Dear Team,\n\nPlease find below the AI-generated weekly performance summary.\n\nHighlights:\n- Overall performance trending 8% above quarterly targets\n- Three areas identified for optimization with potential 20% cost savings\n- New anomaly patterns detected that warrant monitoring\n\nRecommended next steps are outlined below. Please review and confirm priority assignments by end of week.\n\nRegards`,
                urgency: 'MEDIUM' as const,
                actions: 'Launch incentive for underperforming Central dealers', 'Reallocate EV inventory to Eastern region', 'Schedule dealer training for hybrid launch',
              },
              {
                subject: 'Strategic Initiative: Data-Driven Optimization',
                body: `Dear Stakeholders,\n\nOur AI analysis has identified a significant opportunity for operational optimization.\n\nExecutive Summary:\n- Current utilization rate: 78% (target: 90%)\n- Root cause analysis points to 3 primary factors\n- Projected ROI of recommended changes: 2.4x within 6 months\n\nThe attached data supports a phased implementation approach starting with the highest-impact items.\n\nPlease advise on scheduling a planning session.\n\nBest regards`,
                urgency: 'HIGH' as const,
                actions: 'Launch incentive for underperforming Central dealers', 'Reallocate EV inventory to Eastern region', 'Schedule dealer training for hybrid launch',
              },
            ];
            return memos[Math.floor(Math.random() * memos.length)];
          }}
        />
      </div>
    </div>
  );

  const askAiTab = (
    <div className="h-[600px]">
      <AskAI
        title="Ask AI"
        sampleQuestions={[
          'Which dealers are below 80% of quarterly target?',
          'Show EV vs ICE sales trend by region',
          'What is optimal inventory for pickups in Isaan?',
        ]}
        mode="sql"
        onSubmit={async (question, mode) => {
          return {
            answer: `[Demo Mode] Response to: "${question}" (${mode} mode). Connect to Snowflake for live data.`,
            sql: mode === 'sql' ? 'SELECT * FROM CURATED.SUMMARY LIMIT 10;' : undefined,
          };
        }}
      />
    </div>
  );

  const architectureTab = (
    <ArchitectureDiagram
      snowflakeFeatures={['Dynamic Tables (5-min refresh)', 'ML Functions (Forecast + Anomaly)', 'Cortex Search + Agent', 'Semantic View + Intelligence', 'Alerts + Notifications']}
      awsServices={[{ name: 'Amazon S3', role: 'Strategy Docs' }, { name: 'Amazon S3 + Kinesis', role: 'Integration' }, { name: 'Amazon SNS', role: 'Integration' }, { name: 'Amazon QuickSight + Q', role: 'Integration' }]}
    />
  );

  const tabs = [
    { id: 'executive-cockpit', label: 'Executive Cockpit', icon: '📊', content: executiveCockpit },
    { id: 'domain-1', label: 'Demand Forecast', icon: '📈', content: domainTab1 },
    { id: 'domain-2', label: 'Dealer Intelligence', icon: '⚡', content: domainTab2 },
    { id: 'ask-ai', label: 'Ask AI', icon: '🤖', content: askAiTab },
    { id: 'architecture', label: 'Architecture & Data', icon: '🏗️', content: architectureTab },
  ];

  return (
    <AppLayout
      title={title}
      tabs={tabs}
      narrative={narrative}
    />
  );
}
