import { IInputs, IOutputs } from "./generated/ManifestTypes";
import * as React from "react";
import { createRoot, Root } from "react-dom/client";
import PhoneInputt from "./PhoneInput";

interface PageContext {
  entityId: string;
  entityTypeName: string;
}

interface ContextWithPage extends ComponentFramework.Context<IInputs> {
  page: PageContext;
}
const ACTIVITY_TYPES = new Set([
  "phonecall", "email", "task", "appointment",
  "letter", "fax", "socialactivity", "recurringappointmentmaster",
]);

export class PhoneFormatter implements ComponentFramework.StandardControl<IInputs, IOutputs> {
  private notifyOutputChanged!: () => void;
  private root!: Root;
  private context!: ComponentFramework.Context<IInputs>;
  private value = "";
  private disabled = false;
  private required = false;
  private regardingName = "";   // ← fetched async
  private regardingId = "";
  private regardingType = "";

  public init(
    context: ComponentFramework.Context<IInputs>,
    notifyOutputChanged: () => void,
    _state: ComponentFramework.Dictionary,
    container: HTMLDivElement
  ): void {
    this.notifyOutputChanged = notifyOutputChanged;
    this.root = createRoot(container);
    this.syncFromContext(context);
    this.render();
  }

  public updateView(context: ComponentFramework.Context<IInputs>): void {
    const prevValue = this.value;
    const prevDisabled = this.disabled;
    const prevRequired = this.required;

    this.syncFromContext(context);

    if (
      this.value !== prevValue ||
      this.disabled !== prevDisabled ||
      this.required !== prevRequired
    ) {
      this.render();
    }
  }

  private syncFromContext(context: ComponentFramework.Context<IInputs>): void {
    this.context = context;
    this.value = context.parameters.Phone.raw ?? "";
    this.disabled = context.mode.isControlDisabled;
    this.required = context.parameters.Phone.attributes?.RequiredLevel === 2;

    const page = (context as ContextWithPage).page;
    this.regardingId = page?.entityId ?? "";
    this.regardingType = page?.entityTypeName ?? "";

    // Fetch name once when id is first available
    if (this.regardingId && this.regardingType && !this.regardingName) {
      void this.fetchRegardingName();
    }
  }

  private async fetchRegardingName(): Promise<void> {
    try {
      // Pick the correct name field based on entity type
    const nameField = this.regardingType === "account"
      ? "name"
      : ACTIVITY_TYPES.has(this.regardingType.toLowerCase())
      ? "subject"
      : "fullname";

      const result = await this.context.webAPI.retrieveRecord(
        this.regardingType,
        this.regardingId,
        `?$select=${nameField}`
      );

      this.regardingName = (result[nameField] ?? "") as string;
      this.render();
    } catch (e) {
      console.error("fetchRegardingName failed:", e);
      this.regardingName = "";
    }
  }

  private handleValueChange = (v: string): void => {
    if (this.disabled) return;
    this.value = v;
    this.notifyOutputChanged();
  };

  private render(): void {
    this.root.render(
      React.createElement(PhoneInputt, {
        value: this.value,
        onValueChange: this.handleValueChange,
        disabled: this.disabled,
        required: this.required,
        context: this.context,
        regardingId: this.regardingId,
        regardingType: this.regardingType,
        regardingName: this.regardingName,
      })
    );
  }

  public getOutputs(): IOutputs {
    return { Phone: this.value };
  }

  public destroy(): void {
    this.root?.unmount();
  }
}
