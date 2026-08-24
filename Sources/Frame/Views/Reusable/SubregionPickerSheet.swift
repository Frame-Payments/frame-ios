//
//  SubregionPickerSheet.swift
//  Frame-iOS
//

import SwiftUI

/// A SwiftUI sheet that presents a wheel-style picker for selecting a state, province, or territory.
public struct SubregionPickerSheet: View {
    @Binding var selectedCode: String
    @Binding var isPresented: Bool

    /// The wheel's live selection, committed to `selectedCode` only on Done.
    @State private var draftCode: String

    private let title: String
    private let subregions: [AddressSubregion]

    /// Creates a `SubregionPickerSheet`.
    public init(selectedCode: Binding<String>,
                isPresented: Binding<Bool>,
                countryCode: String,
                title: String) {
        self._selectedCode = selectedCode
        self._isPresented = isPresented
        self.title = title

        let available = AddressSubregions.subregions(forCountry: countryCode) ?? []
        self.subregions = available

        let current = selectedCode.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let seed = available.contains { $0.code == current } ? current : (available.first?.code ?? "")
        self._draftCode = State(initialValue: seed)
    }

    /// The content and layout of the subregion picker sheet.
    public var body: some View {
        NavigationView {
            VStack {
                Picker(title, selection: $draftCode) {
                    ForEach(subregions) { subregion in
                        Text(subregion.name)
                            .tag(subregion.code)
                    }
                }
                .labelsHidden()
                .pickerStyle(.wheel)
                .frame(maxHeight: 250)

                Spacer()
            }
            .navigationBarTitle("Choose \(title)", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") {
                selectedCode = draftCode
                isPresented = false
            })
        }
    }
}
