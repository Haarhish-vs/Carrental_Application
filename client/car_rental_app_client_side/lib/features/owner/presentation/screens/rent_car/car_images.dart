import 'package:flutter/material.dart';

import 'car_documents.dart';
import 'rent_car_shared.dart';

class CarImagesScreen extends StatefulWidget {
	const CarImagesScreen({super.key, required this.draft});

	final RentCarDraft draft;

	@override
	State<CarImagesScreen> createState() => _CarImagesScreenState();
}

class _CarImagesScreenState extends State<CarImagesScreen> {
	final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

	late final TextEditingController _frontImageController;
	late final TextEditingController _rearImageController;
	late final TextEditingController _interiorImageController;
	late final TextEditingController _dashboardImageController;

	@override
	void initState() {
		super.initState();
		_frontImageController = TextEditingController(
			text: widget.draft.selectedPhotos.isNotEmpty ? widget.draft.selectedPhotos[0] : '',
		);
		_rearImageController = TextEditingController(
			text: widget.draft.selectedPhotos.length > 1 ? widget.draft.selectedPhotos[1] : '',
		);
		_interiorImageController = TextEditingController(
			text: widget.draft.selectedPhotos.length > 2 ? widget.draft.selectedPhotos[2] : '',
		);
		_dashboardImageController = TextEditingController(
			text: widget.draft.selectedPhotos.length > 3 ? widget.draft.selectedPhotos[3] : '',
		);
	}

	@override
	void dispose() {
		_frontImageController.dispose();
		_rearImageController.dispose();
		_interiorImageController.dispose();
		_dashboardImageController.dispose();
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

	void _goNext() {
		if (!_formKey.currentState!.validate()) {
			return;
		}

		final selectedPhotos = <String>[
			_frontImageController.text.trim(),
			_rearImageController.text.trim(),
			_interiorImageController.text.trim(),
			_dashboardImageController.text.trim(),
		].where((value) => value.isNotEmpty).toList();

		final updatedDraft = widget.draft.copyWith(selectedPhotos: selectedPhotos);

		Navigator.of(context).push(
			buildRentCarSlideRoute(
				CarDocumentsScreen(draft: updatedDraft),
			),
		);
	}

	@override
	Widget build(BuildContext context) {
		return Form(
			key: _formKey,
			child: RentCarScreenScaffold(
				currentStep: 3,
				title: 'Car Images',
				subtitle: 'Add clear photo references so renters can review the car from every angle.',
				onBack: _goBack,
				onNext: _goNext,
				nextLabel: 'Next',
				backLabel: 'Back',
				child: Column(
					children: [
						RentCarSectionCard(
							title: 'Photo Set',
							icon: Icons.photo_library_outlined,
							child: Column(
								children: [
									RentCarTextField(
										controller: _frontImageController,
										label: 'Front View',
										hint: 'Paste image URL or local path',
										icon: Icons.photo_camera_front_outlined,
										validator: (value) => _requiredText(value, 'front view image'),
										textInputAction: TextInputAction.next,
									),
									const SizedBox(height: 14),
									RentCarTextField(
										controller: _rearImageController,
										label: 'Rear View',
										hint: 'Paste image URL or local path',
										icon: Icons.photo_camera_back_outlined,
										validator: (value) => _requiredText(value, 'rear view image'),
										textInputAction: TextInputAction.next,
									),
									const SizedBox(height: 14),
									RentCarTextField(
										controller: _interiorImageController,
										label: 'Interior View',
										hint: 'Paste image URL or local path',
										icon: Icons.chair_outlined,
										validator: (value) => _requiredText(value, 'interior view image'),
										textInputAction: TextInputAction.next,
									),
									const SizedBox(height: 14),
									RentCarTextField(
										controller: _dashboardImageController,
										label: 'Dashboard View',
										hint: 'Paste image URL or local path',
										icon: Icons.dashboard_outlined,
										validator: (value) => _requiredText(value, 'dashboard view image'),
									),
								],
							),
						),
						const SizedBox(height: 16),
						RentCarSectionCard(
							title: 'Photo Guidelines',
							icon: Icons.tips_and_updates_outlined,
							child: Column(
								crossAxisAlignment: CrossAxisAlignment.start,
								children: const [
									Text('Use bright, straight-on shots for best presentation.'),
									SizedBox(height: 8),
									Text('Keep the car clean and visible in every photo.'),
									SizedBox(height: 8),
									Text('Add the main exterior angles before detail close-ups.'),
								],
							),
						),
					],
				),
			),
		);
	}
}
