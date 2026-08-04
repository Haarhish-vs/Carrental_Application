import 'package:flutter/material.dart';

import 'rent_car_shared.dart';

class CarDocumentsScreen extends StatefulWidget {
	const CarDocumentsScreen({super.key, required this.draft});

	final RentCarDraft draft;

	@override
	State<CarDocumentsScreen> createState() => _CarDocumentsScreenState();
}

class _CarDocumentsScreenState extends State<CarDocumentsScreen> {
	final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

	late final TextEditingController _registrationCertificateController;
	late final TextEditingController _insurancePolicyController;
	late final TextEditingController _ownerIdController;
	late final TextEditingController _permitController;

	@override
	void initState() {
		super.initState();
		_registrationCertificateController = TextEditingController();
		_insurancePolicyController = TextEditingController();
		_ownerIdController = TextEditingController();
		_permitController = TextEditingController();
	}

	@override
	void dispose() {
		_registrationCertificateController.dispose();
		_insurancePolicyController.dispose();
		_ownerIdController.dispose();
		_permitController.dispose();
		super.dispose();
	}

	String? _requiredText(String? value, String label) {
		if (value == null || value.trim().isEmpty) {
			return 'Enter $label';
		}
		return null;
	}

	void _goBack() {
		Navigator.of(context).pop();
	}

	Future<void> _submit() async {
		if (!_formKey.currentState!.validate()) {
			return;
		}

		final summary = <String, String>{
			'Brand': widget.draft.brand,
			'Model': widget.draft.model,
			'Year': widget.draft.manufacturingYear,
			'Daily price': widget.draft.dailyPrice,
			'Documents': 'Ready for review',
		};

		await showDialog<void>(
			context: context,
			builder: (context) {
				return AlertDialog(
					title: const Text('Car Submitted'),
					content: Column(
						mainAxisSize: MainAxisSize.min,
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							const Text('Your rent-out request has been prepared for review.'),
							const SizedBox(height: 16),
							...summary.entries.map(
								(entry) => Padding(
									padding: const EdgeInsets.only(bottom: 8),
									child: Text('${entry.key}: ${entry.value}'),
								),
							),
						],
					),
					actions: [
						FilledButton(
							onPressed: () => Navigator.of(context).pop(),
							child: const Text('Close'),
						),
					],
				);
			},
		);
	}

	@override
	Widget build(BuildContext context) {
		return Form(
			key: _formKey,
			child: RentCarScreenScaffold(
				currentStep: 4,
				title: 'Documents',
				subtitle: 'Capture the document references needed for verification and approval.',
				onBack: _goBack,
				onNext: _submit,
				nextLabel: 'Submit',
				backLabel: 'Back',
				isLastStep: true,
				child: Column(
					children: [
						RentCarSectionCard(
							title: 'Verification Details',
							icon: Icons.verified_user_outlined,
							child: Column(
								children: [
									RentCarTextField(
										controller: _registrationCertificateController,
										label: 'Registration Certificate Number',
										hint: 'Enter official document number',
										icon: Icons.receipt_long_outlined,
										validator: (value) => _requiredText(value, 'registration certificate number'),
										textInputAction: TextInputAction.next,
									),
									const SizedBox(height: 14),
									RentCarTextField(
										controller: _insurancePolicyController,
										label: 'Insurance Policy Number',
										hint: 'Enter active insurance reference',
										icon: Icons.policy_outlined,
										validator: (value) => _requiredText(value, 'insurance policy number'),
										textInputAction: TextInputAction.next,
									),
									const SizedBox(height: 14),
									RentCarTextField(
										controller: _ownerIdController,
										label: 'Owner ID Reference',
										hint: 'Enter owner identity reference',
										icon: Icons.badge_outlined,
										validator: (value) => _requiredText(value, 'owner ID reference'),
										textInputAction: TextInputAction.next,
									),
									const SizedBox(height: 14),
									RentCarTextField(
										controller: _permitController,
										label: 'Permit / License Reference',
										hint: 'Enter permit or license number',
										icon: Icons.credit_card_outlined,
										validator: (value) => _requiredText(value, 'permit or license reference'),
									),
								],
							),
						),
						const SizedBox(height: 16),
						RentCarSectionCard(
							title: 'Review Summary',
							icon: Icons.fact_check_outlined,
							child: Column(
								crossAxisAlignment: CrossAxisAlignment.start,
								children: [
									Text('Brand: ${widget.draft.brand}'),
									const SizedBox(height: 8),
									Text('Model: ${widget.draft.model}'),
									const SizedBox(height: 8),
									Text('Year: ${widget.draft.manufacturingYear}'),
									const SizedBox(height: 8),
									Text('Daily Price: ${widget.draft.dailyPrice}'),
								],
							),
						),
					],
				),
			),
		);
	}
}
