import 'package:flutter/material.dart';

import '../services/ai_service.dart';

/// A built-in project template that produces a ready-made plan (no AI call).
class ProjectTemplateDef {
  final String name;
  final String category;
  final IconData icon;
  final String projectType;
  final String complexity;
  final String duration;
  final List<PlanMilestone> milestones;

  const ProjectTemplateDef({
    required this.name,
    required this.category,
    required this.icon,
    required this.projectType,
    required this.complexity,
    required this.duration,
    required this.milestones,
  });

  ProjectPlan toPlan({String objective = ''}) => ProjectPlan(
        projectType: projectType,
        complexity: complexity,
        duration: duration,
        objective: objective,
        requiredAreas: const [],
        milestones: milestones,
        risks: const [],
        provider: 'template',
      );
}

const List<ProjectTemplateDef> kProjectTemplates = [
  ProjectTemplateDef(
    name: 'Business Startup',
    category: 'Business',
    icon: Icons.rocket_launch_outlined,
    projectType: 'Business Creation',
    complexity: 'High',
    duration: '6 months',
    milestones: [
      PlanMilestone('Idea validation',
          [PlanTask('Define the problem & customer', 'high'), PlanTask('Validate demand', 'high')]),
      PlanMilestone('Market research',
          [PlanTask('Analyse competitors', 'medium'), PlanTask('Size the market', 'medium')]),
      PlanMilestone('Business plan',
          [PlanTask('Financial model', 'high'), PlanTask('Go-to-market plan', 'medium')]),
      PlanMilestone('Registration',
          [PlanTask('Register the company', 'high'), PlanTask('Open bank account', 'medium')]),
      PlanMilestone('Funding',
          [PlanTask('Prepare pitch', 'medium'), PlanTask('Secure capital', 'high')]),
      PlanMilestone('Launch',
          [PlanTask('First customers', 'critical'), PlanTask('Operations live', 'high')]),
    ],
  ),
  ProjectTemplateDef(
    name: 'Product Launch',
    category: 'Product',
    icon: Icons.new_releases_outlined,
    projectType: 'Technology Product',
    complexity: 'Medium',
    duration: '3 months',
    milestones: [
      PlanMilestone('Research',
          [PlanTask('User research', 'high'), PlanTask('Define requirements', 'high')]),
      PlanMilestone('Development',
          [PlanTask('Build MVP', 'critical'), PlanTask('Internal review', 'medium')]),
      PlanMilestone('Testing',
          [PlanTask('QA & bug fixes', 'high'), PlanTask('Beta feedback', 'medium')]),
      PlanMilestone('Marketing',
          [PlanTask('Launch assets', 'medium'), PlanTask('Campaign plan', 'medium')]),
      PlanMilestone('Sales',
          [PlanTask('Enable sales', 'high'), PlanTask('Go live', 'critical')]),
    ],
  ),
  ProjectTemplateDef(
    name: 'Import Project',
    category: 'Trade',
    icon: Icons.local_shipping_outlined,
    projectType: 'Import',
    complexity: 'Medium',
    duration: '2 months',
    milestones: [
      PlanMilestone('Supplier search',
          [PlanTask('Shortlist suppliers', 'high'), PlanTask('Request samples', 'medium')]),
      PlanMilestone('Negotiation',
          [PlanTask('Agree price & terms', 'high')]),
      PlanMilestone('Contract',
          [PlanTask('Sign purchase agreement', 'high')]),
      PlanMilestone('Shipping',
          [PlanTask('Book freight', 'medium'), PlanTask('Track shipment', 'medium')]),
      PlanMilestone('Customs',
          [PlanTask('Clear customs', 'high'), PlanTask('Pay duties', 'medium')]),
      PlanMilestone('Delivery',
          [PlanTask('Receive & inspect goods', 'high')]),
    ],
  ),
  ProjectTemplateDef(
    name: 'Construction',
    category: 'Construction',
    icon: Icons.apartment_outlined,
    projectType: 'Construction',
    complexity: 'High',
    duration: '9 months',
    milestones: [
      PlanMilestone('Design',
          [PlanTask('Architectural plans', 'high')]),
      PlanMilestone('Permits',
          [PlanTask('Submit permit applications', 'high')]),
      PlanMilestone('Contractor',
          [PlanTask('Select contractor', 'high'), PlanTask('Sign contract', 'medium')]),
      PlanMilestone('Materials',
          [PlanTask('Procure materials', 'medium')]),
      PlanMilestone('Inspection',
          [PlanTask('Final inspection', 'high'), PlanTask('Handover', 'medium')]),
    ],
  ),
  ProjectTemplateDef(
    name: 'Software Project',
    category: 'Technology',
    icon: Icons.code,
    projectType: 'Software Development',
    complexity: 'Medium',
    duration: '3 months',
    milestones: [
      PlanMilestone('Requirements',
          [PlanTask('Gather requirements', 'high'), PlanTask('Define scope', 'high')]),
      PlanMilestone('Design',
          [PlanTask('Architecture & UX', 'medium')]),
      PlanMilestone('Development',
          [PlanTask('Build features', 'critical')]),
      PlanMilestone('Testing',
          [PlanTask('QA & fixes', 'high')]),
      PlanMilestone('Deployment',
          [PlanTask('Release', 'critical'), PlanTask('Monitor', 'medium')]),
    ],
  ),
  ProjectTemplateDef(
    name: 'Marketing Campaign',
    category: 'Marketing',
    icon: Icons.campaign_outlined,
    projectType: 'Marketing Campaign',
    complexity: 'Low',
    duration: '6 weeks',
    milestones: [
      PlanMilestone('Strategy',
          [PlanTask('Define audience & goal', 'high')]),
      PlanMilestone('Content',
          [PlanTask('Create assets', 'medium')]),
      PlanMilestone('Launch',
          [PlanTask('Go live across channels', 'high')]),
      PlanMilestone('Measure',
          [PlanTask('Track results & optimise', 'medium')]),
    ],
  ),
];
